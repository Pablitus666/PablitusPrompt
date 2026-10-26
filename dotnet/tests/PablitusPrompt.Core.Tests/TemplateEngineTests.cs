using PablitusPrompt.Core.Templating;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class TemplateEngineTests
{
    private readonly TemplateEngine _engine = new();

    [Fact]
    public void RendersVariablesAndNestedProperties()
    {
        var context = new
        {
            UserName = "pablo",
            Path = new { Current = @"D:\dev" },
        };

        var result = _engine.Render("{{ .UserName }}:{{ .Path.Current }}", context);

        Assert.Equal(@"pablo:D:\dev", result);
    }

    [Fact]
    public void PropertyLookupIsCaseInsensitive()
    {
        var result = _engine.Render("{{ .username }}", new { UserName = "pablo" });

        Assert.Equal("pablo", result);
    }

    [Fact]
    public void MissingPropertiesRenderAsEmptyWithoutThrowing()
    {
        var result = _engine.Render("x{{ .Missing.Deep.Property }}y", new { UserName = "pablo" });

        Assert.Equal("xy", result);
    }

    [Fact]
    public void RendersDictionaryValues()
    {
        var context = new Dictionary<string, object?>
        {
            ["Path"] = new Dictionary<string, object?> { ["Folder"] = "src" },
        };

        Assert.Equal("src", _engine.Render("{{ .Path.Folder }}", context));
    }

    [Theory]
    [InlineData("x", "yes")]
    [InlineData("y", "no")]
    public void RendersIfElse(string value, string expected)
    {
        var result = _engine.Render(
            "{{ if eq .Value \"x\" }}yes{{ else }}no{{ end }}",
            new { Value = value });

        Assert.Equal(expected, result);
    }

    [Theory]
    [InlineData(1, "one")]
    [InlineData(2, "two")]
    [InlineData(3, "other")]
    public void RendersElseIfChains(int value, string expected)
    {
        var template = "{{ if eq .Value 1 }}one{{ else if eq .Value 2 }}two{{ else }}other{{ end }}";

        Assert.Equal(expected, _engine.Render(template, new { Value = value }));
    }

    [Fact]
    public void RendersNestedIfBlocks()
    {
        var template = "{{ if .Outer }}{{ if .Inner }}both{{ else }}outer{{ end }}{{ else }}none{{ end }}";

        Assert.Equal("both", _engine.Render(template, new { Outer = true, Inner = true }));
        Assert.Equal("outer", _engine.Render(template, new { Outer = true, Inner = false }));
        Assert.Equal("none", _engine.Render(template, new { Outer = false, Inner = true }));
    }

    [Fact]
    public void AppliesStringFunctions()
    {
        Assert.Equal("ABC", _engine.Render("{{ upper \"abc\" }}", null));
        Assert.Equal("abc", _engine.Render("{{ lower \"ABC\" }}", null));
        Assert.Equal("abc", _engine.Render("{{ trim \"  abc  \" }}", null));
        Assert.Equal("b-b", _engine.Render("{{ replace \"a\" \"b\" \"a-a\" }}", null));
        Assert.Equal("HI", _engine.Render("{{ upper (trim \"  hi  \") }}", null));
    }

    [Fact]
    public void DefaultUsesFallbackForEmptyValues()
    {
        Assert.Equal("fallback", _engine.Render("{{ default \"fallback\" .Missing }}", new { }));
        Assert.Equal("fallback", _engine.Render("{{ default \"fallback\" \"\" }}", null));
        Assert.Equal("value", _engine.Render("{{ default \"fallback\" \"value\" }}", null));
        Assert.Equal("fallback", _engine.Render("{{ default \"fallback\" 0 }}", null));
    }

    [Fact]
    public void SupportsBooleanOperators()
    {
        var context = new { A = 1, B = 2 };

        Assert.Equal(string.Empty, _engine.Render("{{ if and (eq .A 1) (not (eq .B 2)) }}ok{{ end }}", context));
        Assert.Equal("ok", _engine.Render("{{ if and (eq .A 1) (not (eq .B 3)) }}ok{{ end }}", context));
        Assert.Equal("ok", _engine.Render("{{ if or (eq .A 9) (eq .A 1) }}ok{{ end }}", context));
        Assert.Equal(string.Empty, _engine.Render("{{ if or (eq .A 9) (eq .A 8) }}ok{{ end }}", context));
        Assert.Equal("ok", _engine.Render("{{ if not (eq .A 2) }}ok{{ end }}", context));
    }

    [Fact]
    public void ContainsUsesOhMyPoshArgumentOrder()
    {
        Assert.Equal("yes", _engine.Render("{{ if contains \"ell\" .Word }}yes{{ end }}", new { Word = "hello" }));
        Assert.Equal(string.Empty, _engine.Render("{{ if contains \"zzz\" .Word }}yes{{ end }}", new { Word = "hello" }));
    }

    [Fact]
    public void ComparesNumbersAcrossNumericTypes()
    {
        Assert.Equal("equal", _engine.Render("{{ if eq .Value 2.0 }}equal{{ end }}", new { Value = 2 }));
        Assert.Equal("different", _engine.Render("{{ if ne .Value 2 }}different{{ end }}", new { Value = 3 }));
    }

    [Fact]
    public void EscapesStringLiterals()
    {
        Assert.Equal("{{", _engine.Render("{{ \"{{\" }}", null));
        Assert.Equal("a\"b", _engine.Render("{{ \"a\\\"b\" }}", null));
        Assert.Equal("line\nbreak", _engine.Render("{{ \"line\\nbreak\" }}", null));
    }

    [Fact]
    public void TrimsWhitespaceWithDashMarkers()
    {
        Assert.Equal("abc", _engine.Render("a  {{- \"b\" -}}  c", null));
    }

    [Fact]
    public void ReportsUnterminatedActionWithPosition()
    {
        var exception = Assert.Throws<TemplateParseException>(
            () => _engine.Compile("abc {{ upper \"x\""));

        Assert.Equal(1, exception.Line);
        Assert.True(exception.Column > 1);
        Assert.Contains("Unterminated", exception.Message);
        Assert.Contains("line 1", exception.Message);
    }

    [Fact]
    public void ReportsUnterminatedIfWithPosition()
    {
        var exception = Assert.Throws<TemplateParseException>(
            () => _engine.Compile("{{ if .A }}x"));

        Assert.Contains("Unterminated 'if'", exception.Message);
        Assert.Contains("line 1", exception.Message);
    }

    [Fact]
    public void ReportsUnknownFunctionWithPosition()
    {
        var exception = Assert.Throws<TemplateParseException>(
            () => _engine.Compile("line1\n{{ nope .A }}"));

        Assert.Equal(2, exception.Line);
        Assert.Contains("Unknown template function 'nope'", exception.Message);
        Assert.Contains("line 2", exception.Message);
    }

    [Fact]
    public void ReportsUnexpectedElse()
    {
        var exception = Assert.Throws<TemplateParseException>(
            () => _engine.Compile("{{ else }}"));

        Assert.Contains("Unexpected 'else'", exception.Message);
    }

    [Fact]
    public void ReportsWrongFunctionArity()
    {
        var exception = Assert.Throws<TemplateParseException>(
            () => _engine.Compile("{{ upper }}"));

        Assert.Contains("expects 1 argument", exception.Message);
    }

    [Fact]
    public void ReportsMissingEndAfterElse()
    {
        var exception = Assert.Throws<TemplateParseException>(
            () => _engine.Compile("{{ if .A }}a{{ else }}b"));

        Assert.Contains("Unterminated 'if'", exception.Message);
    }

    [Fact]
    public void TryRenderReturnsFalseForParseErrors()
    {
        var succeeded = _engine.TryRender("{{ nope }}", null, out var result, out var error);

        Assert.False(succeeded);
        Assert.Empty(result);
        Assert.NotNull(error);
    }

    [Fact]
    public void CompilesOnceAndReusesTemplate()
    {
        var first = _engine.Compile("{{ .Name }}");
        var second = _engine.Compile("{{ .Name }}");

        Assert.Same(first, second);
    }
}
