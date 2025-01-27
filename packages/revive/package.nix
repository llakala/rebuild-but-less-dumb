{ llakaLib, ... }:

llakaLib.writeFishApplication
{
  name = "revive"; # Reuse Environment Variable If Value Encountered

  text =
  /* fish */
  ''
    for val in $argv
        if [ -n "$val" ]
            echo $val
            break
        end
    end
  '';
}
