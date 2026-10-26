using PablitusPrompt.Core.Configuration;
using PablitusPrompt.Core.Omp;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class OmpThemeImporterTests
{
    private readonly OmpThemeImporter _importer = new();

    [Fact]
    public void ImportsRepositoryOhMyPoshTheme()
    {
        var theme = _importer.ImportFile(TestPaths.OmpTheme);

        Assert.Equal("Pablitus", theme.Name);
        Assert.Equal("oh-my-posh", theme.Source);
        Assert.Equal("powerline", theme.Renderer);
        Assert.True(theme.FinalSpace);
        Assert.Equal(2, theme.Blocks.Count);
        Assert.Equal(2, theme.Blocks[0].Segments.Count);

        var session = theme.Blocks[0].Segments[0];
        Assert.Equal("session", session.Type);
        Assert.Equal("plain", session.Style);
        Assert.Equal("#8AE234", session.Foreground);
        Assert.Equal("┌──({{ .UserName }}㉿{{ .HostName }})", session.Template);

        var path = theme.Blocks[0].Segments[1];
        Assert.Equal("path", path.Type);
        Assert.Equal("-[{{ .Path }}]", path.Template);
        Assert.Equal("agnoster", path.Properties["style"]);

        Assert.True(theme.Blocks[1].Newline);
        Assert.Equal("text", theme.Blocks[1].Segments[0].Type);
        Assert.Equal("└─$ ", theme.Blocks[1].Segments[0].Template);
    }

    [Fact]
    public void ImportsAllSupportedSegmentTypes()
    {
        var theme = _importer.ImportFile(TestPaths.ExampleOmpTheme);

        var segments = theme.Blocks[0].Segments;
        Assert.Equal(6, segments.Count);
        Assert.Equal(
            new[] { "session", "path", "git", "time", "exit", "text" },
            segments.Select(segment => segment.Type));
        Assert.Equal("user", segments[0].Foreground);
        Assert.Equal("#8AE234", theme.Palette["user"]);
        Assert.Equal("powerline", segments[1].Style);
        Assert.Equal("#5e81ac", segments[1].Background);
        Assert.Equal("agnoster", segments[1].Properties["style"]);
        Assert.True(theme.Blocks[1].Newline);
    }

    [Fact]
    public void ImportedThemePassesPpfValidation()
    {
        var theme = _importer.ImportFile(TestPaths.ExampleOmpTheme);
        var errors = PpfConfigValidator.ValidateTheme(theme);

        Assert.Empty(errors);
    }

    [Fact]
    public void ImportedThemeSerializesAndReloads()
    {
        var theme = _importer.ImportFile(TestPaths.ExampleOmpTheme);
        var json = PpfConfigSerializer.SerializeTheme(theme);
        var reloaded = PpfConfigSerializer.LoadThemeFromJson(json);

        Assert.Equal(theme.Blocks.Count, reloaded.Blocks.Count);
        Assert.Equal("oh-my-posh", reloaded.Source);
    }

    [Fact]
    public void ImportsRightPromptTransientPromptAndTooltips()
    {
        const string json = """
        {
          "version": 3,
          "transient_prompt": {
            "template": "{{ .Shell }}> ",
            "right_template": "{{ .Path.Folder }}",
            "filler": ".",
            "newline": true,
            "foreground": "#ffffff",
            "background": "transparent"
          },
          "tooltips_action": "extend",
          "tooltips": [
            {
              "type": "text",
              "tips": ["git", "g"],
              "style": "diamond",
              "foreground": "#ffffff",
              "background": "#ff0000",
              "template": "git"
            },
            {
              "type": "os",
              "tips": ["uname"],
              "template": "ignored"
            }
          ],
          "blocks": [
            {
              "type": "prompt",
              "segments": [ { "type": "text", "template": "left" } ]
            },
            {
              "type": "rprompt",
              "alignment": "right",
              "filler": ".",
              "overflow": "hide",
              "segments": [ { "type": "text", "template": "right" } ]
            }
          ]
        }
        """;

        var theme = _importer.Import(json, "advanced.omp.json", ignoreUnsupportedSegments: true);

        Assert.Equal("extend", theme.TooltipsAction);
        Assert.NotNull(theme.TransientPrompt);
        Assert.Equal("{{ .Path.Folder }}", theme.TransientPrompt!.RightTemplate);
        Assert.Equal(".", theme.TransientPrompt.Filler);
        Assert.True(theme.TransientPrompt.Newline);
        Assert.Equal("#ffffff", theme.TransientPrompt.Foreground);
        Assert.Null(theme.TransientPrompt.Background);

        var rightBlock = Assert.Single(theme.Blocks, block => block.Type == "rprompt");
        Assert.Equal(".", rightBlock.Filler);
        Assert.Equal("hide", rightBlock.Overflow);

        var tooltip = Assert.Single(theme.Tooltips);
        Assert.Equal("text", tooltip.Type);
        Assert.Equal(new[] { "git", "g" }, tooltip.Tips);
        Assert.Equal("diamond", tooltip.Style);
    }

    [Fact]
    public void RejectsUnsupportedSegmentWithPath()
    {
        const string json = """
        {
          "blocks": [
            {
              "segments": [
                { "type": "os", "template": "x" }
              ]
            }
          ]
        }
        """;

        var exception = Assert.Throws<OmpImportException>(() => _importer.Import(json, "theme.omp.json"));

        Assert.Equal("blocks[0].segments[0].type", exception.Path);
        Assert.Contains("Unsupported Oh My Posh segment type 'os'", exception.Message);
        Assert.Contains("session", exception.Message);
    }

    [Fact]
    public void IgnoresUnsupportedSegmentsWhenRequested()
    {
        const string json = """
        {
          "blocks": [
            {
              "segments": [
                { "type": "os", "template": "x" },
                { "type": "text", "template": "ok" }
              ]
            }
          ]
        }
        """;

        var theme = _importer.Import(json, "theme.omp.json", ignoreUnsupportedSegments: true);

        var segment = Assert.Single(theme.Blocks[0].Segments);
        Assert.Equal("text", segment.Type);
    }

    [Fact]
    public void RejectsInvalidJson()
    {
        var exception = Assert.Throws<OmpImportException>(() => _importer.Import("{"));

        Assert.Contains("Invalid Oh My Posh JSON", exception.Message);
    }

    [Fact]
    public void RejectsMissingBlocks()
    {
        var exception = Assert.Throws<OmpImportException>(() => _importer.Import("""{"version":3}"""));

        Assert.Equal("blocks", exception.Path);
        Assert.Contains("blocks", exception.Message);
    }

    [Fact]
    public void RejectsThemeWithoutSupportedSegments()
    {
        const string json = """
        {
          "blocks": [
            { "segments": [ { "type": "os" } ] }
          ]
        }
        """;

        var exception = Assert.Throws<OmpImportException>(
            () => _importer.Import(json, "theme.omp.json", ignoreUnsupportedSegments: true));

        Assert.Equal("blocks", exception.Path);
        Assert.Contains("does not contain any supported segment", exception.Message);
    }

    [Fact]
    public void SuppliesDefaultTemplatesWhenMissing()
    {
        const string json = """
        {
          "blocks": [
            {
              "segments": [
                { "type": "session" },
                { "type": "path" },
                { "type": "git" },
                { "type": "text" },
                { "type": "time" },
                { "type": "exit" }
              ]
            }
          ]
        }
        """;

        var theme = _importer.Import(json);
        var templates = theme.Blocks[0].Segments.Select(segment => segment.Template).ToArray();

        Assert.Equal("{{ .UserName }}@{{ .HostName }}", templates[0]);
        Assert.Equal("{{ .Path.Current }}", templates[1]);
        Assert.Equal("{{ .Git.Branch }}", templates[2]);
        Assert.Equal(string.Empty, templates[3]);
        Assert.Equal("{{ .Time }}", templates[4]);
        Assert.Contains(".ExitCode", templates[5]);
    }

    [Fact]
    public void MapsUnknownStyleToPlain()
    {
        const string json = """
        {
          "blocks": [
            {
              "segments": [
                { "type": "text", "style": "minimal", "template": "x" },
                { "type": "text", "style": "unexpected", "template": "y" }
              ]
            }
          ]
        }
        """;

        var theme = _importer.Import(json);

        Assert.Equal("plain", theme.Blocks[0].Segments[0].Style);
        Assert.Equal("plain", theme.Blocks[0].Segments[1].Style);
    }

    [Fact]
    public void HonorsNameOverride()
    {
        var theme = _importer.ImportFile(TestPaths.OmpTheme, name: "Custom");

        Assert.Equal("Custom", theme.Name);
    }
}
