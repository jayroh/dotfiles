vim.g.EditorConfig_exclude_patterns = {'fugitive://.*'}

if vim.fn.has("unix") == 1 then
  local uname = vim.fn.system("uname")
  
  if uname == "Darwin\n" then
    vim.g.EditorConfig_exec_path = '/usr/local/bin/editorconfig'
  else
    vim.g.EditorConfig_exec_path = '/usr/bin/editorconfig'
  end
end