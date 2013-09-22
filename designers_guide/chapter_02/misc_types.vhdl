package misc_types is
  type short is range 0 to 255;
  type fraction is range -1.0 to +1.0;
  type current is range integer'low to integer'high
    units nA;
          uA = 1000 nA;
          mA = 1000 uA;
          A  = 1000 mA;
    end units;
  type colors is (red, yellow, green);
end package misc_types;
