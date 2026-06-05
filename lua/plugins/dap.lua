-- Debug Adapter Protocol (DAP) stack for C/C++ using GDB (cpptools via Mason)
-- Keymaps: <leader>d* (see below) - all shown in <leader>h keymap browser
return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio", -- required by nvim-dap-ui
			"theHamsta/nvim-dap-virtual-text", -- inline variable values
			"jay-babu/mason-nvim-dap.nvim", -- bridges Mason <-> nvim-dap
			"mason-org/mason.nvim",
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")

			require("mason-nvim-dap").setup({
				ensure_installed = { "cpptools" },
				automatic_installation = true,
				handlers = {
					function(config)
						require("mason-nvim-dap").default_setup(config)
					end,
				},
			})

			-- mason-nvim-dap's default handler points cppdbg at exepath('OpenDebugAD7'),
			-- which is empty since Mason packages aren't on $PATH; register explicitly.
			-- get_install_path() was removed in Mason 2.0, so use stdpath("data")/mason directly.
			local install_path = vim.fn.stdpath("data") .. "/mason/packages/cpptools"
			local binary = vim.fn.glob(install_path .. "/**/OpenDebugAD7", false, true)[1]
			if binary then
				dap.adapters.cppdbg = { id = "cppdbg", type = "executable", command = binary }
			end

			-- inline variable values next to the code
			require("nvim-dap-virtual-text").setup({})

			-- panels: scopes, breakpoints, call stack, watches, ...
			dapui.setup()

			-- "c" in the breakpoints/stacks panels: open the target location in the main
			vim.api.nvim_create_autocmd("FileType", {
				pattern = { "dapui_breakpoints", "dapui_stacks" },
				callback = function(ev)
					vim.keymap.set("n", "c", function()
						local panel_win = vim.api.nvim_get_current_win()
						pcall(vim.cmd, "normal o") -- run the remapped open
						pcall(vim.api.nvim_set_current_win, panel_win) -- restore focus immediately
						vim.schedule(function() -- safety restore after any deferred focus steal
							pcall(vim.api.nvim_set_current_win, panel_win)
						end)
					end, { buffer = ev.buf, nowait = true, desc = "Preview location in main window (keep focus)" })
				end,
			})

			-- auto-open / auto-close the UI panels when a session starts/ends
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			-- C launch config (prompts for executable path, stops at main)
			dap.configurations.c = {
				{
					name = "Launch (gdb)",
					type = "cppdbg",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopAtEntry = true,
					MIMode = "gdb",
				},
			}
			-- reuse the same config for C++
			dap.configurations.cpp = dap.configurations.c

			-- keymaps -------------------------------------------------------
			vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug : Toggle breakpoint" })
			vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug : Continue / start" })
			vim.keymap.set("n", "<leader>dn", dap.step_over, { desc = "Debug : Step over" })
			vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug : Step into" })
			vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Debug : Step out" })
			vim.keymap.set("n", "<leader>dx", dap.terminate, { desc = "Debug : Terminate" })
			vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Debug : Toggle UI" })
			vim.keymap.set("n", "<leader>de", dapui.eval, { desc = "Debug : Evaluate expression" })
			vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Debug : Pause" })
			vim.keymap.set("n", "<leader>dr", dap.restart, { desc = "Debug : Restart" })
			vim.keymap.set("n", "<leader>dw", function()
				local expr = vim.fn.expand("<cword>")
				require("dapui").elements.watches.add(expr)
			end, { desc = "Debug : Add word under cursor to watch" })
		end,
	},
}
