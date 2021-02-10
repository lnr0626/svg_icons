defmodule SvgIconsTest do
  defmodule Endpoint do
    use Phoenix.Endpoint, otp_app: :svg_icons
  end

  @endpoint Endpoint

  use ExUnit.Case
  use Surface.LiveViewTest

  defmodule HeroIcon do
    use SvgIcons,
      surface: false,
      path: ["support/test-icons/optimized", {:variant, [:outline, :solid], "outline"}, :icon]
  end

  defmodule HeroIconWithSurface do
    use SvgIcons,
      surface: true,
      path: ["support/test-icons/optimized", {:variant, [:outline, :solid], "outline"}, :icon]
  end

  test "allows rendering svgs" do
    require HeroIcon

    assert {:safe, value} = HeroIcon.svg({"outline", "adjustments"})

    assert to_string(value) == """
           <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">\
             <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"/>\
           </svg>\
           """
  end

  test "creates surface specific methods" do
    html =
      render_surface do
        ~H"""
        <#HeroIconWithSurface variant="outline" icon="adjustments" />
        """
      end

    assert html == """
    <svg class="" data-variant="outline" data-icon="adjustments" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">\
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"/>\
    </svg>
    """
  end
end
