return {
  {
    "mfussenegger/nvim-lint",
    opts = {
      -- Это принудительно очищает список линтеров для Markdown
      linters_by_ft = {
        markdown = {},
      },
    },
  },
}
