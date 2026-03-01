-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

local java_format_group = vim.api.nvim_create_augroup("java_format_like_vscode", { clear = true })

local function format_range(bufnr, start_row, start_col, end_row, end_col)
  local ok, conform = pcall(require, "conform")
  if not ok then
    return
  end

  conform.format({
    bufnr = bufnr,
    async = false,
    lsp_format = "prefer",
    quiet = true,
    range = {
      start = { start_row, start_col },
      ["end"] = { end_row, end_col },
    },
  })
end

local function format_buffer(bufnr)
  local last_row = vim.api.nvim_buf_line_count(bufnr)
  local last_line = vim.api.nvim_buf_get_lines(bufnr, last_row - 1, last_row, false)[1] or ""
  format_range(bufnr, 1, 0, last_row, #last_line)
end

local function format_last_change(bufnr)
  local start_pos = vim.api.nvim_buf_get_mark(bufnr, "[")
  local end_pos = vim.api.nvim_buf_get_mark(bufnr, "]")
  if start_pos[1] == 0 or end_pos[1] == 0 then
    return
  end

  local end_line = vim.api.nvim_buf_get_lines(bufnr, end_pos[1] - 1, end_pos[1], false)[1] or ""
  local end_col = math.max(end_pos[2], #end_line)
  format_range(bufnr, start_pos[1], start_pos[2], end_pos[1], end_col)
end

vim.api.nvim_create_autocmd("FileType", {
  group = java_format_group,
  pattern = "java",
  callback = function(event)
    -- LazyVim default save-format is full-buffer. Java は変更行のみフォーマットに切り替える。
    vim.b[event.buf].autoformat = false
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  group = java_format_group,
  pattern = "*.java",
  callback = function(event)
    if vim.g.autoformat == false then
      return
    end

    local ok, gitsigns = pcall(require, "gitsigns")
    if not ok then
      -- gitsigns がない場合は保存時フォーマット自体は維持する。
      format_buffer(event.buf)
      return
    end

    local hunks = gitsigns.get_hunks(event.buf) or {}
    if #hunks == 0 then
      if vim.bo[event.buf].modified then
        format_buffer(event.buf)
      end
      return
    end

    local ranges = {}
    for _, hunk in ipairs(hunks) do
      local added = hunk.added
      if added and added.count and added.count > 0 then
        local start_row = added.start
        local end_row = added.start + added.count - 1
        local end_line = vim.api.nvim_buf_get_lines(event.buf, end_row - 1, end_row, false)[1] or ""
        ranges[#ranges + 1] = {
          start = { start_row, 0 },
          ["end"] = { end_row, #end_line },
        }
      end
    end

    table.sort(ranges, function(a, b)
      return a.start[1] > b.start[1]
    end)

    for _, range in ipairs(ranges) do
      format_range(event.buf, range.start[1], range.start[2], range["end"][1], range["end"][2])
    end
  end,
})

if not vim.g.java_format_on_paste_hooked then
  vim.g.java_format_on_paste_hooked = true
  vim.paste = (function(overridden)
    return function(lines, phase)
      local ok = overridden(lines, phase)
      if not ok then
        return false
      end

      if phase == -1 or phase == 3 then
        vim.schedule(function()
          local bufnr = vim.api.nvim_get_current_buf()
          if vim.bo[bufnr].filetype ~= "java" then
            return
          end
          if vim.g.autoformat == false then
            return
          end
          format_last_change(bufnr)
        end)
      end

      return ok
    end
  end)(vim.paste)
end
