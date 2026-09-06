function fish_greeting
    if type -q diyfetch
        diyfetch
    else if type -q fastfetch
        fastfetch
    end
end
