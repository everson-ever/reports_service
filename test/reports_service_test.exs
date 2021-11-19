defmodule ReportsServiceTest do
  use ExUnit.Case
  doctest ReportsService

  test "greets the world" do
    assert ReportsService.hello() == :world
  end
end
