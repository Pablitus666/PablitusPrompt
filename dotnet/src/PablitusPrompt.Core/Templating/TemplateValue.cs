using System.Collections;
using System.Globalization;
using System.Reflection;
using System.Text.Json;

namespace PablitusPrompt.Core.Templating;

/// <summary>
/// Value helpers shared by the template evaluator and the renderers. Missing
/// properties resolve to <c>null</c>; formatting turns <c>null</c> into an empty
/// string. No template evaluation ever throws for a missing value.
/// </summary>
public static class TemplateValue
{
    public static object? ResolvePath(object? root, string path)
    {
        if (root is null || string.IsNullOrEmpty(path) || path == ".")
        {
            return root;
        }

        var current = root;
        var normalized = path[0] == '.' ? path[1..] : path;
        if (normalized.Length == 0)
        {
            return current;
        }

        foreach (var segment in normalized.Split('.'))
        {
            if (segment.Length == 0)
            {
                return null;
            }

            current = ResolveMember(current, segment);
            if (current is null)
            {
                return null;
            }
        }

        return current;
    }

    public static object? ResolveMember(object? target, string name)
    {
        if (target is null || string.IsNullOrEmpty(name))
        {
            return null;
        }

        switch (target)
        {
            case JsonElement element:
                return ResolveJsonMember(element, name);

            case IDictionary<string, object?> genericDictionary:
                if (genericDictionary.TryGetValue(name, out var genericValue))
                {
                    return genericValue;
                }

                foreach (var pair in genericDictionary)
                {
                    if (string.Equals(pair.Key, name, StringComparison.OrdinalIgnoreCase))
                    {
                        return pair.Value;
                    }
                }

                return null;

            case IReadOnlyDictionary<string, object?> readOnlyDictionary:
                if (readOnlyDictionary.TryGetValue(name, out var readOnlyValue))
                {
                    return readOnlyValue;
                }

                foreach (var pair in readOnlyDictionary)
                {
                    if (string.Equals(pair.Key, name, StringComparison.OrdinalIgnoreCase))
                    {
                        return pair.Value;
                    }
                }

                return null;

            case IDictionary dictionary:
                if (dictionary.Contains(name))
                {
                    return dictionary[name];
                }

                foreach (DictionaryEntry entry in dictionary)
                {
                    if (entry.Key is string key && string.Equals(key, name, StringComparison.OrdinalIgnoreCase))
                    {
                        return entry.Value;
                    }
                }

                return null;
        }

        var type = target.GetType();
        var property = type.GetProperty(
            name,
            BindingFlags.Instance | BindingFlags.Public | BindingFlags.IgnoreCase);

        if (property is not null && property.GetMethod is not null && property.GetIndexParameters().Length == 0)
        {
            try
            {
                return property.GetValue(target);
            }
            catch
            {
                return null;
            }
        }

        var field = type.GetField(
            name,
            BindingFlags.Instance | BindingFlags.Public | BindingFlags.IgnoreCase);

        if (field is not null)
        {
            try
            {
                return field.GetValue(target);
            }
            catch
            {
                return null;
            }
        }

        return null;
    }

    private static object? ResolveJsonMember(JsonElement element, string name)
    {
        if (element.ValueKind == JsonValueKind.Object)
        {
            if (element.TryGetProperty(name, out var exact))
            {
                return exact;
            }

            foreach (var property in element.EnumerateObject())
            {
                if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
                {
                    return property.Value;
                }
            }
        }

        return null;
    }

    public static string Format(object? value)
    {
        switch (value)
        {
            case null:
                return string.Empty;
            case string text:
                return text;
            case char character:
                return character.ToString();
            case bool boolean:
                return boolean ? "true" : "false";
            case JsonElement element:
                return FormatJson(element);
            case DateTimeOffset dateTimeOffset:
                return dateTimeOffset.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
            case DateTime dateTime:
                return dateTime.ToString("yyyy-MM-dd HH:mm:ss", CultureInfo.InvariantCulture);
            case TimeSpan timeSpan:
                return timeSpan.ToString("c", CultureInfo.InvariantCulture);
            case IFormattable formattable:
                return formattable.ToString(null, CultureInfo.InvariantCulture) ?? string.Empty;
            case IEnumerable enumerable:
                return string.Join(" ", enumerable.Cast<object?>().Select(Format));
            default:
                return value.ToString() ?? string.Empty;
        }
    }

    private static string FormatJson(JsonElement element) =>
        element.ValueKind switch
        {
            JsonValueKind.String => element.GetString() ?? string.Empty,
            JsonValueKind.Number => element.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            JsonValueKind.Null or JsonValueKind.Undefined => string.Empty,
            _ => element.GetRawText(),
        };

    public static bool IsTruthy(object? value)
    {
        switch (value)
        {
            case null:
                return false;
            case bool boolean:
                return boolean;
            case string text:
                return text.Length > 0;
            case JsonElement element:
                return element.ValueKind switch
                {
                    JsonValueKind.Null or JsonValueKind.Undefined => false,
                    JsonValueKind.False => false,
                    JsonValueKind.String => (element.GetString() ?? string.Empty).Length > 0,
                    JsonValueKind.Number => element.TryGetDecimal(out var number) && number != 0,
                    JsonValueKind.Array => element.GetArrayLength() > 0,
                    JsonValueKind.Object => element.EnumerateObject().Any(),
                    _ => true,
                };
            case sbyte or byte or short or ushort or int or uint or long or ulong or float or double or decimal:
                return Convert.ToDecimal(value, CultureInfo.InvariantCulture) != 0;
            case IEnumerable enumerable:
                return enumerable.Cast<object?>().Any();
            default:
                return true;
        }
    }

    public static bool IsEmpty(object? value)
    {
        switch (value)
        {
            case null:
                return true;
            case string text:
                return text.Length == 0;
            case bool boolean:
                return !boolean;
            case JsonElement element:
                return !IsTruthy(element);
            case sbyte or byte or short or ushort or int or uint or long or ulong or float or double or decimal:
                return Convert.ToDecimal(value, CultureInfo.InvariantCulture) == 0;
            case IEnumerable enumerable:
                return !enumerable.Cast<object?>().Any();
            default:
                return false;
        }
    }

    public static bool AreEqual(object? left, object? right)
    {
        if (left is null || right is null)
        {
            return left is null && right is null;
        }

        if (IsNumeric(left) && IsNumeric(right))
        {
            try
            {
                return Convert.ToDecimal(left, CultureInfo.InvariantCulture) ==
                       Convert.ToDecimal(right, CultureInfo.InvariantCulture);
            }
            catch (OverflowException)
            {
                return Convert.ToDouble(left, CultureInfo.InvariantCulture) ==
                       Convert.ToDouble(right, CultureInfo.InvariantCulture);
            }
        }

        if (left is bool leftBoolean && right is bool rightBoolean)
        {
            return leftBoolean == rightBoolean;
        }

        return string.Equals(Format(left), Format(right), StringComparison.Ordinal);
    }

    public static bool IsNumeric(object value) =>
        value is sbyte or byte or short or ushort or int or uint or long or ulong or float or double or decimal;

    public static int Compare(object? left, object? right)
    {
        if (left is null || right is null)
        {
            return left is null ? (right is null ? 0 : -1) : 1;
        }

        if (IsNumeric(left) && IsNumeric(right))
        {
            return Convert.ToDecimal(left, CultureInfo.InvariantCulture)
                .CompareTo(Convert.ToDecimal(right, CultureInfo.InvariantCulture));
        }

        return string.CompareOrdinal(Format(left), Format(right));
    }
}
