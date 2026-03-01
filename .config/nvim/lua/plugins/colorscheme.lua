return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
  {
    'xiyaowong/transparent.nvim',
    lazy = false, -- make sure we load this during startup
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      require('transparent').setup({
        extra_groups = {
          -- 'menubarBaseBg',
          -- 'menubarBg1',
          -- 'menubarBg2',
          -- 'menubarBg3',
          -- 'menubarBg4',
        },
        exclude_groups = { 'Comment', 'CursorLine', 'CursorLineNr' },
      })

      vim.cmd('TransparentEnable')
    end,
  },
}
