require('gen').prompts['Enhance_Code_NoExpl'] = {
  prompt = "Enhance the following code. Only output the result in format:\n```$filetype\n...\n```\nDo not offer an explanation of the enhancements, just respond with the enhancement code. Maintain the original indentation of the code as much as possible. Here is the code:\n\n```$filetype\n$text\n```",
  replace = true,
  extract = "```$filetype\n(.-)```",
}
