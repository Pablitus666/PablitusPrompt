using System.Collections;

namespace PablitusPrompt.Core.Templating;

internal static class TemplateExpressionEvaluator
{
    private static readonly Dictionary<string, (int Min, int Max)> Signatures =
        new(StringComparer.OrdinalIgnoreCase)
        {
            ["upper"] = (1, 1),
            ["lower"] = (1, 1),
            ["trim"] = (1, 1),
            ["replace"] = (3, 3),
            ["default"] = (2, 2),
            ["eq"] = (2, int.MaxValue),
            ["ne"] = (2, 2),
            ["contains"] = (2, 2),
            ["and"] = (2, int.MaxValue),
            ["or"] = (2, int.MaxValue),
            ["not"] = (1, 1),
        };

    public static bool TryGetSignature(string name, out int min, out int max)
    {
        if (Signatures.TryGetValue(name, out var signature))
        {
            min = signature.Min;
            max = signature.Max;
            return true;
        }

        min = 0;
        max = 0;
        return false;
    }

    public static bool IsKnownFunction(string name) => Signatures.ContainsKey(name);

    public static object? EvaluateFunction(
        string name,
        IReadOnlyList<TemplateExpression> arguments,
        object? context,
        int position)
    {
        if (!Signatures.TryGetValue(name, out var signature))
        {
            throw new InvalidOperationException($"Unknown template function '{name}' at index {position}.");
        }

        if (arguments.Count < signature.Min || arguments.Count > signature.Max)
        {
            throw new InvalidOperationException(
                $"Template function '{name}' expects {DescribeArity(signature.Min, signature.Max)} argument(s) but got {arguments.Count}.");
        }

        switch (name.ToLowerInvariant())
        {
            case "upper":
                return TemplateValue.Format(Evaluate(arguments, 0, context)).ToUpperInvariant();

            case "lower":
                return TemplateValue.Format(Evaluate(arguments, 0, context)).ToLowerInvariant();

            case "trim":
                return TemplateValue.Format(Evaluate(arguments, 0, context)).Trim();

            case "replace":
            {
                var oldValue = TemplateValue.Format(Evaluate(arguments, 0, context));
                var newValue = TemplateValue.Format(Evaluate(arguments, 1, context));
                var source = TemplateValue.Format(Evaluate(arguments, 2, context));
                if (oldValue.Length == 0)
                {
                    return source;
                }

                return source.Replace(oldValue, newValue, StringComparison.Ordinal);
            }

            case "default":
            {
                var fallback = Evaluate(arguments, 0, context);
                var candidate = Evaluate(arguments, 1, context);
                return TemplateValue.IsEmpty(candidate) ? fallback : candidate;
            }

            case "eq":
            {
                var first = Evaluate(arguments, 0, context);
                for (var i = 1; i < arguments.Count; i++)
                {
                    if (TemplateValue.AreEqual(first, Evaluate(arguments, i, context)))
                    {
                        return true;
                    }
                }

                return false;
            }

            case "ne":
                return !TemplateValue.AreEqual(
                    Evaluate(arguments, 0, context),
                    Evaluate(arguments, 1, context));

            case "contains":
                return Contains(
                    Evaluate(arguments, 0, context),
                    Evaluate(arguments, 1, context));

            case "and":
                foreach (var argument in arguments)
                {
                    if (!TemplateValue.IsTruthy(argument.Evaluate(context)))
                    {
                        return false;
                    }
                }

                return true;

            case "or":
                foreach (var argument in arguments)
                {
                    if (TemplateValue.IsTruthy(argument.Evaluate(context)))
                    {
                        return true;
                    }
                }

                return false;

            case "not":
                return !TemplateValue.IsTruthy(Evaluate(arguments, 0, context));

            default:
                throw new InvalidOperationException($"Unknown template function '{name}' at index {position}.");
        }
    }

    private static object? Evaluate(IReadOnlyList<TemplateExpression> arguments, int index, object? context) =>
        arguments[index].Evaluate(context);

    private static bool Contains(object? first, object? second)
    {
        // Oh My Posh follows the Sprig order: contains <needle> <haystack>.
        if (first is string needle)
        {
            if (second is string haystack)
            {
                return haystack.Contains(needle, StringComparison.Ordinal);
            }

            if (second is null)
            {
                return false;
            }
        }

        if (first is IDictionary dictionary)
        {
            if (second is not null && dictionary.Contains(second))
            {
                return true;
            }

            if (second is string key)
            {
                foreach (DictionaryEntry entry in dictionary)
                {
                    if (entry.Key is string candidate && string.Equals(candidate, key, StringComparison.OrdinalIgnoreCase))
                    {
                        return true;
                    }
                }
            }

            return false;
        }

        if (first is not string && first is IEnumerable firstSequence)
        {
            return firstSequence.Cast<object?>().Any(item => TemplateValue.AreEqual(item, second));
        }

        if (second is not string && second is IEnumerable secondSequence)
        {
            return secondSequence.Cast<object?>().Any(item => TemplateValue.AreEqual(item, first));
        }

        return false;
    }

    private static string DescribeArity(int min, int max) =>
        max == int.MaxValue ? $"at least {min}" : min == max ? min.ToString() : $"{min}-{max}";
}
