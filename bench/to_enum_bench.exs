defmodule GenEnum.ToEnumBench do
  use Benchfella
  alias GenEnum.ToEnumBench.Helper.Utils, as: Helper
  @success {:ok, :MAC}

  bench "direct match atom" do
    @success = Helper.to_enum(:MAC)
  end

  bench "direct match string" do
    @success = Helper.to_enum("MAC")
  end

  bench "match atom" do
    @success = Helper.to_enum(:mac)
  end

  bench "match string" do
    @success = Helper.to_enum("mac")
  end

  bench "mismatch atom" do
    {:error, _} = Helper.to_enum(:MACOS)
  end

  bench "mismatch string" do
    {:error, _} = Helper.to_enum("MACOS")
  end
end
