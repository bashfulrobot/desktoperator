function starship_transient_prompt_func
    starship module character
end
function starship_transient_rprompt_func
    starship module time
end

function starship_preprompt_user_func(prompt)
    print("🚀")
end

load(io.popen('starship init cmd'):read("*a"))()

starship init fish | source
enable_transience
