local response_format = "Do not offer explanations or commentary. Respond EXACTLY and ONLY in this format:\n```$ftype\n<your code>\n```"

return {
  {
    'romainl/apprentice',
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme apprentice]])
    end,
  },
  'tpope/vim-fugitive',
  'tpope/vim-rhubarb', -- provides :GBrowse
  {
    'kana/vim-textobj-user',
    priority = 999, -- make sure this gets loaded before other plugins that rely on it
    lazy = false -- eager load so vim-textobj-entire works
  },
  'kana/vim-textobj-entire', -- provides vie, vae, yie, etc.
  'coderifous/textobj-word-column.vim', -- provides vic, vac, etc.
  'junegunn/fzf',
  'junegunn/fzf.vim',
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = { 'nvim-lua/plenary.nvim' },
  },
  'itspriddle/vim-marked',
  -- 'sheerun/vim-polyglot',
  'tpope/vim-rails',
  'tpope/vim-bundler', -- provides :Bundle open
  'tpope/vim-rake',
  -- 'ngmy/vim-rubocop', -- provides :RuboCop
  'tpope/vim-apathy',
  -- 'mechatroner/rainbow_csv',
  -- 'posva/vim-vue',
  {
    'greggh/claude-code.nvim',
    dependencies = {
      "nvim-lua/plenary.nvim", -- Required for git operations
    },
    config = function()
      require("claude-code").setup()
    end
  },
  {
    dir = '~/Repos/cheet.nvim',
    config = function()
      require('cheet').setup({
        paths = { '~/.config/vim-cheatsheet.yaml' }
      })
    end
  },
  {
    "David-Kunz/gen.nvim",
    opts = {
        model = "deepseek-coder-v2", -- The default model to use.
        host = "localhost", -- The host running the Ollama service.
        port = "11434", -- The port on which the Ollama service is listening.
        quit_map = "q", -- set keymap for close the response window
        retry_map = "<c-r>", -- set keymap to re-send the current prompt
        init = function(options) pcall(io.popen, "ollama serve > /dev/null 2>&1 &") end,
        -- Function to initialize Ollama
        command = function(options)
            local body = {model = options.model, stream = true}
            return "curl --silent --no-buffer -X POST http://" .. options.host .. ":" .. options.port .. "/api/chat -d $body"
        end,
        -- The command for the Ollama service. You can use placeholders $prompt, $model and $body (shellescaped).
        -- This can also be a command string.
        -- The executed command must return a JSON object with { response, context }
        -- (context property is optional).
        -- list_models = '<omitted lua function>', -- Retrieves a list of model names
        display_mode = "float", -- The display mode. Can be "float" or "split".
        show_prompt = false, -- Shows the prompt submitted to Ollama.
        show_model = false, -- Displays which model you are using at the beginning of your chat session.
        no_auto_close = false, -- Never closes the window automatically.
        debug = false -- Prints errors and the command which is run.
    }
  },
  -- {
  --   "nomnivore/ollama.nvim",
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",
  --   },
  --
  --   -- All the user commands added by the plugin
  --   cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },
  --
  --   keys = {
  --     -- Sample keybind for prompt menu. Note that the <c-u> is important for selections to work properly.
  --     {
  --       "<leader>oo",
  --       ":<c-u>lua require('ollama').prompt()<cr>",
  --       desc = "ollama prompt",
  --       mode = { "n", "v" },
  --     },
  --
  --     -- Sample keybind for direct prompting. Note that the <c-u> is important for selections to work properly.
  --     {
  --       "<leader>oG",
  --       ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
  --       desc = "ollama Generate Code",
  --       mode = { "n", "v" },
  --     },
  --     {
  --       "<leader>oC",
  --       ":<c-u>lua require('ollama').prompt('Complete_Code')<cr>",
  --       desc = "ollama Complete Code",
  --       mode = { "n", "v" },
  --     },
  --   },
  --
  --   ---@type Ollama.Config
  --   opts = {
  --     model = "deepseek-coder-v2",
  --     prompts = {
  --       Complete_Code = {
  --         prompt = "Modify or complete the following $ftype code according to any instructions given through comments in the code. "
  --                 .. response_format
  --                 .. "\n\n```$ftype\n$sel\n```",
  --         action = "replace",
  --       },
  --       Complete_Code_Debug = {
  --         prompt = "Modify or complete the following $ftype code according to any instructions given through comments in the code. "
  --                 .. response_format
  --                 .. "\n\n```$ftype\n$sel\n```",
  --         action = "display",
  --       }
  --     }
  --   }
  -- }
}
