defmodule SvgIcons do
  @moduledoc """
  This module is used to handle creating modules for SVG icons. This allows using inline svgs without
  having to maintain the svgs inline.

  Examples:
    defmodule HeroIcons do
      use SvgIcons,
        surface: false,
        path: ["support/test-icons/optimized", {:variant, [:outline, :solid], "outline"}, :icon]
    end

    ...

    > HeroIcons.svg({"outline", "chart-pie"}, class: "w-4 h-4")
    {:safe, "<svg class="w-4 h-4" ...>...</svg>"}
  """
  defmacro __using__(opts) do
    path_parts = Keyword.get(opts, :path)
    extension = Keyword.get(opts, :ext, ".svg")
    path_sep = Keyword.get(opts, :path_sep, "/")
    base_dir = Keyword.get(opts, :base_dir, Path.dirname(__CALLER__.file))
    include_surface = Keyword.get(opts, :surface, true)

    quote do
      @path_pattern SvgIcons.collect_pattern_parts(unquote(path_parts))

      @svgs SvgIcons.read_svgs(
              unquote(base_dir),
              @path_pattern,
              unquote(extension),
              unquote(path_sep)
            )

      defp svgs(), do: @svgs

      with {:module, _} <- Code.ensure_compiled(Surface) do
        unquote(if include_surface, do: define_surface_macro(__CALLER__))
      end

      def svg(id, attrs \\ []) do
        Phoenix.HTML.raw(render_svg(id, attrs))
      end

      def render_svg(id, attrs), do: SvgIcons.render_svg(svgs(), id, attrs)
    end
  end

  def render_svg(svgs, id, attrs) do
    if Map.has_key?(svgs, id) do
      [head, tail] = Map.get(svgs, id)

      [head, translate_attrs(attrs), tail]
    else
      IO.warn("Could not find icon for #{inspect(id)}")
      ["<span>", "Failed to load icon ", inspect(id), "</span>"]
    end
  end

  def define_surface_macro(caller) do
    quote do
      use Surface.MacroComponent

      for {name, _, _, default} <- @path_pattern do
        Surface.API.put_assign(
          __ENV__,
          :prop,
          name,
          :string,
          [default: default],
          [default: default],
          unquote(caller.line)
        )
      end

      prop(id, :string)
      prop(class, :string)
      prop(opts, :keyword, default: [])

      def expand(attributes, _children, meta),
        do: SvgIcons.expand(__MODULE__, svgs(), attributes, meta, @path_pattern)
    end
  end

  defmacro read_svgs(base_dir, pattern_parts, extension, path_sep) do
    quote do
      SvgIcons.read_svgs(
        __MODULE__,
        unquote(base_dir),
        unquote(pattern_parts),
        unquote(extension),
        unquote(path_sep)
      )
    end
  end

  def expand(module, svgs, attributes, meta, path_pattern) do
    with {:module, _module} <- Code.ensure_compiled(Surface.MacroComponent) do
      props = Surface.MacroComponent.eval_static_props!(module, attributes, meta.caller)

      defaults =
        for {name, _, _, default} <- path_pattern, into: %{} do
          {name, default}
        end

      capture_names =
        path_pattern
        |> Enum.map(fn {name, _, _, _} -> name end)
        |> Enum.reject(&is_nil/1)

      id =
        capture_names
        |> Enum.map(fn name -> props[name] || Map.get(defaults, name) end)
        |> List.to_tuple()

      class = props[:class] || ""
      opts = props[:opts] || []

      attrs =
        opts ++
          [class: class] ++
          Enum.map(capture_names, fn name ->
            {"data-#{to_string(name)}", props[name]}
          end)

      struct!(Surface.AST.Literal, value: render_svg(svgs, id, attrs) |> IO.iodata_to_binary())
    end
  end

  def read_svgs(module, base_dir, pattern_parts, extension, path_sep) do
    regex =
      ((pattern_parts
        |> Enum.map(fn {_, pattern, _, _} -> pattern end)
        |> Enum.join(path_sep)) <> Regex.escape(extension))
      |> Regex.compile!()

    capture_names =
      pattern_parts
      |> Enum.map(fn {name, _, _, _} -> name end)
      |> Enum.reject(&is_nil/1)

    capture_name_strings = Enum.map(capture_names, &to_string/1)

    files =
      ((pattern_parts
        |> Enum.map(fn {_, _, wildcard, _} -> wildcard end)
        |> Enum.join(path_sep)) <> extension)
      |> Path.expand(base_dir)
      |> Path.wildcard()
      |> Enum.sort()

    for path <- files,
        relative_path = Path.relative_to(path, base_dir),
        captures = Regex.named_captures(regex, relative_path),
        captures != nil,
        id =
          capture_name_strings
          |> Enum.map(fn name -> captures[name] end)
          |> List.to_tuple(),
        into: %{} do
      Module.put_attribute(module, :external_resource, Path.relative_to_cwd(path))

      "<svg" <> contents =
        path
        |> File.read!()
        |> String.replace("\n", "")
        |> String.trim()

      {id, ["<svg", contents]}
    end
  end

  def collect_pattern_parts(path_parts) do
    Enum.map(path_parts, fn
      path when is_binary(path) ->
        path_segment(path)

      name when is_atom(name) ->
        named_path_segment(name)

      {name, default} when is_atom(name) and is_binary(default) ->
        named_path_segment(name, default)

      {name, options} when is_atom(name) and is_list(options) ->
        enum_path_segment(name, options)

      {name, options, default} when is_atom(name) and is_list(options) and is_binary(default) ->
        enum_path_segment(name, options, default)
    end)
  end

  defp path_segment(path), do: {nil, Regex.escape(path), path, nil}

  defp named_path_segment(name, default \\ nil),
    do: {name, "(?<#{to_string(name)}>[^/]+)", "*", default}

  defp enum_path_segment(name, values, default \\ nil) do
    regex_or =
      values
      |> Enum.map(&to_string/1)
      |> Enum.map(&Regex.escape/1)
      |> Enum.join("|")

    wildcard_or =
      values
      |> Enum.map(&to_string/1)
      |> Enum.join(",")

    {name, "(?<#{to_string(name)}>#{regex_or})", "{#{wildcard_or}}", default}
  end

  defp translate_attrs([]) do
    []
  end

  defp translate_attrs([{key, true} | tail]) do
    [" ", to_string(key), translate_attrs(tail)]
  end

  defp translate_attrs([{_, value} | tail]) when is_nil(value) or value == false do
    translate_attrs(tail)
  end

  defp translate_attrs([{key, value} | tail]) do
    [" ", to_string(key), ~S(="), value, ~S("), translate_attrs(tail)]
  end
end
