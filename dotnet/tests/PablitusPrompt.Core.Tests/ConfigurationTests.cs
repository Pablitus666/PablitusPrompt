using PablitusPrompt.Core.Configuration;
using Xunit;

namespace PablitusPrompt.Core.Tests;

public sealed class ConfigurationTests
{
    [Fact]
    public void LoadsMinimalConfigurationWithRootBlocks()
    {
        const string json = """
        {
          "renderer": "plain",
          "blocks": [
            { "segments": [ { "type": "text", "template": "hello" } ] }
          ]
        }
        """;

        var config = PpfConfigSerializer.LoadConfigFromJson(json, "memory.json");

        Assert.Equal("plain", config.Renderer);
        Assert.Single(config.Blocks);
        Assert.Equal("text", config.Blocks[0].Segments[0].Type);
        Assert.Equal("hello", config.Blocks[0].Segments[0].Template);
    }

    [Fact]
    public void LoadsEmbeddedTheme()
    {
        const string json = """
        {
          "renderer": "powerline",
          "theme": {
            "name": "Test",
            "blocks": [
              { "segments": [ { "type": "session" } ] }
            ]
          }
        }
        """;

        var config = PpfConfigSerializer.LoadConfigFromJson(json);

        Assert.NotNull(config.Theme);
        Assert.Equal("Test", config.Theme!.Name);
        Assert.Single(config.Theme.Blocks);
    }

    [Fact]
    public void LoadsRepositoryExamples()
    {
        var theme = PpfConfigSerializer.LoadTheme(TestPaths.NordTheme);
        var config = PpfConfigSerializer.LoadConfig(TestPaths.ExampleConfig);

        Assert.Equal("Nord", theme.Name);
        Assert.Equal(2, theme.Blocks.Count);
        Assert.NotNull(config.Theme);
        Assert.Equal("powerline", config.Renderer);
        Assert.True(config.Cache?.Enabled ?? false);
    }

    [Fact]
    public void DetectsDocumentKinds()
    {
        var configJson = File.ReadAllText(TestPaths.ExampleConfig);
        var themeJson = File.ReadAllText(TestPaths.NordTheme);

        Assert.Equal(PpfDocumentKind.Config, PpfConfigSerializer.DetectDocumentKind(configJson));
        Assert.Equal(PpfDocumentKind.Theme, PpfConfigSerializer.DetectDocumentKind(themeJson));
        Assert.Equal(
            PpfDocumentKind.Config,
            PpfConfigSerializer.DetectDocumentKind("""{"renderer":"plain","blocks":[]}"""));
    }

    [Fact]
    public void RejectsMalformedJsonWithPath()
    {
        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson("""{"renderer": """));

        Assert.NotEmpty(exception.Errors);
        Assert.Contains("Invalid PPF", exception.Message);
        Assert.Contains("configuration", exception.Message);
    }

    [Fact]
    public void RejectsMissingSegmentTypeWithFieldPath()
    {
        const string json = """
        {
          "theme": {
            "blocks": [
              { "segments": [ { "template": "x" } ] }
            ]
          }
        }
        """;

        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(json, "broken.json"));

        Assert.Contains(
            exception.Errors,
            error => error.Path == "theme.blocks[0].segments[0].type" &&
                     error.Message.Contains("required", StringComparison.OrdinalIgnoreCase));
    }

    [Fact]
    public void RejectsInvalidStyleWithFieldPath()
    {
        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(ThemeWithSegment("""{ "type": "text", "style": "fancy" }""")));

        Assert.Contains(
            exception.Errors,
            error => error.Path == "theme.blocks[0].segments[0].style");
    }

    [Fact]
    public void RejectsInvalidTimeoutWithFieldPath()
    {
        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(
                ThemeWithSegment("""{ "type": "text", "timeoutMs": 0 }""")));

        Assert.Contains(
            exception.Errors,
            error => error.Path == "theme.blocks[0].segments[0].timeoutMs");
    }

    [Fact]
    public void RejectsInvalidColorWithFieldPath()
    {
        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(
                ThemeWithSegment("""{ "type": "text", "foreground": "#12" }""")));

        Assert.Contains(
            exception.Errors,
            error => error.Path == "theme.blocks[0].segments[0].foreground");
    }

    [Fact]
    public void RejectsTemplateSyntaxErrorsWithFieldPathAndPosition()
    {
        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(
                ThemeWithSegment("""{ "type": "text", "template": "{{ if .A }}x" }""")));

        var error = Assert.Single(exception.Errors);
        Assert.Equal("theme.blocks[0].segments[0].template", error.Path);
        Assert.Contains("line 1", error.Message);
    }

    [Fact]
    public void RejectsDuplicateSegmentNames()
    {
        const string json = """
        {
          "theme": {
            "blocks": [
              {
                "segments": [
                  { "type": "text", "name": "same", "template": "a" },
                  { "type": "text", "name": "same", "template": "b" }
                ]
              }
            ]
          }
        }
        """;

        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(json));

        Assert.Contains(exception.Errors, error => error.Path == "theme.blocks[0].segments[1].name");
    }

    [Fact]
    public void RejectsUnknownRenderer()
    {
        const string json = """
        {
          "renderer": "fancy",
          "blocks": [ { "segments": [ { "type": "text", "template": "x" } ] } ]
        }
        """;

        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(json));

        Assert.Contains(exception.Errors, error => error.Path == "renderer");
    }

    [Fact]
    public void RejectsConfigurationWithoutBlocks()
    {
        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson("""{ "renderer": "plain" }"""));

        Assert.Contains(exception.Errors, error => error.Path == "theme");
    }

    [Fact]
    public void RoundTripsThemeThroughJson()
    {
        var original = PpfConfigSerializer.LoadTheme(TestPaths.NordTheme);
        var json = PpfConfigSerializer.SerializeTheme(original);
        var roundTripped = PpfConfigSerializer.LoadThemeFromJson(json);

        Assert.Equal(original.Name, roundTripped.Name);
        Assert.Equal(original.Blocks.Count, roundTripped.Blocks.Count);
        Assert.Equal(
            original.Blocks[0].Segments[0].Template,
            roundTripped.Blocks[0].Segments[0].Template);
    }

    [Fact]
    public void SerializesCamelCaseAndUnicode()
    {
        var theme = new ThemeConfig
        {
            Name = "Ñandú",
            FinalSpace = true,
            Blocks =
            {
                new BlockConfig
                {
                    Segments =
                    {
                        new SegmentConfig { Type = "text", Template = "❯" },
                    },
                },
            },
        };

        var json = PpfConfigSerializer.SerializeTheme(theme);

        Assert.Contains("\"finalSpace\"", json);
        Assert.Contains("Ñandú", json);
        Assert.Contains("❯", json);
    }

    [Fact]
    public void LoadsTransientPromptTooltipsAndAdvancedBlockFields()
    {
        const string json = """
        {
          "transientPrompt": {
            "template": "{{ .Shell }}> ",
            "rightTemplate": "{{ .Path.Folder }}",
            "filler": ".",
            "newline": true,
            "foreground": "white",
            "background": "#000000"
          },
          "tooltipsAction": "prepend",
          "tooltips": [
            {
              "type": "text",
              "tips": ["git"],
              "template": "git",
              "foreground": "#ffffff"
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
              "filler": "-",
              "overflow": "break",
              "segments": [ { "type": "text", "template": "right" } ]
            }
          ]
        }
        """;

        var config = PpfConfigSerializer.LoadConfigFromJson(json);

        Assert.NotNull(config.TransientPrompt);
        Assert.True(config.TransientPrompt!.Newline);
        Assert.Equal(".", config.TransientPrompt.Filler);
        Assert.Equal("prepend", config.TooltipsAction);
        Assert.Single(config.Tooltips);
        Assert.Equal(new[] { "git" }, config.Tooltips[0].Tips);
        Assert.Equal("-", config.Blocks[1].Filler);
        Assert.Equal("break", config.Blocks[1].Overflow);
    }

    [Fact]
    public void ValidatesAdvancedPromptFields()
    {
        const string json = """
        {
          "tooltipsAction": "append",
          "tooltips": [
            { "type": "text", "tips": ["git commit"], "template": "git" }
          ],
          "blocks": [
            { "segments": [ { "type": "text", "template": "left" } ] },
            {
              "type": "rprompt",
              "alignment": "right",
              "overflow": "wrap",
              "segments": [ { "type": "text", "template": "right" } ]
            },
            {
              "type": "rprompt",
              "alignment": "right",
              "segments": [ { "type": "text", "template": "again" } ]
            }
          ]
        }
        """;

        var exception = Assert.Throws<PpfConfigurationException>(
            () => PpfConfigSerializer.LoadConfigFromJson(json));

        Assert.Contains(exception.Errors, error => error.Path == "tooltipsAction");
        Assert.Contains(exception.Errors, error => error.Path == "tooltips[0].tips[0]");
        Assert.Contains(exception.Errors, error => error.Path == "blocks[1].overflow");
        Assert.Contains(exception.Errors, error => error.Path == "blocks[2].type");
    }

    private static string ThemeWithSegment(string segmentJson) =>
        $$"""
        {
          "theme": {
            "blocks": [
              { "segments": [ {{segmentJson}} ] }
            ]
          }
        }
        """;
}
