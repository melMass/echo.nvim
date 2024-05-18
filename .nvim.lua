-- NOTE: This requires vim.opt.exrc = true
require("lspconfig").rust_analyzer.setup({
	settings = {
		["rust-analyzer"] = {
			cargo = {
				features = { "nightly" },
			},
		},
	},
})
