require('gen').prompts['Complete_Code'] = {
  prompt = "Modify or complete the following code according to any instructions given through comments. \z
    Do not give explanations. Respond exactly and only in the format:\n```$filetype\n...\n```\n\z
    Here is the code:\n\n```$filetype\n$text\n```",
  replace = true,
  extract = "```$filetype\n(.-)```",
}

require('gen').prompts['Simplify_Code'] = {
  prompt = "Simplify and make more readable the following code. Follow any additional instrutions given through comments. \z
    Do not give explanations. Respond exactly and only in the format:\n```$filetype\n...\n```\n\z
    Here is the code:\n\n```$filetype\n$text\n```",
  replace = true,
  extract = "```$filetype\n(.-)```",
}
