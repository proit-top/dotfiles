return {
  "stevearc/conform.nvim",
  opts = {
    -- 1. Настраиваем форматтеры
    formatters_by_ft = {
      javascript = { "prettierd" },
      typescript = { "prettierd" },
      yaml = { "prettierd" }, -- Теперь Prettier будет форматировать YAML
      sql = {}, -- Оставляем пустым, чтобы не ломать скрипты инициализации
    },
    -- 2. Глобальные настройки для Prettier
    formatters = {
      prettierd = {
        prepend_args = { "--print-width", "200" }, -- Запрет переноса строк до 200 символов!
      },
    },
  },
}