local M = {}

M.config = {
	template_dir = os.getenv("HOME") .. "/.config/nvim/templates/",
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts)
end

local function short_uuid()
	local time = os.time()
	local random = math.random(10000000, 99999999) -- Ensure 8 digits
	return string.format("%08x", time):sub(-8) .. string.format("%08d", random):sub(-8)
end

---@param dest_path_with_filename string -- The directory path where the file will be created
---@param template_file string -- The template file name within the templates directory
---@param template_values table<string, string> -- Table containing the values to fill out the template
M.create_and_open_file_with_custom_template = function(dest_path_with_filename, template_file, template_values)
	-- Check if file exists
	local file = io.open(dest_path_with_filename, "r")
	if file then
		print("File already exists: " .. dest_path_with_filename)
		file:close() -- Important to close the file handle if the file exists
		return -- Do not proceed if the file exists
	end

	-- Load template function
	local function load_template(template_path)
		local tmp_file, err = io.open(template_path, "r")
		if not tmp_file then
			print("Error loading template: " .. err)
			return nil
		end
		local content = tmp_file:read("*all")
		tmp_file:close()
		return content
	end

	local template_path = M.config.template_dir .. template_file
	local template_content = load_template(template_path)
	if not template_content then
		return -- Template loading failed
	end

	--- TODO: Extract those as functions into the config
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.datetime = os.date("%Y-%m-%d %H:%M") -- Current date and time
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.date = os.date("%Y-%m-%d") -- Current date
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.time = os.date("%H:%M") -- Current time
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.id = short_uuid() -- Unique ID using uuidgen, trim newline
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.user = os.getenv("USER") -- Current system user = os.date("%Y-%m-%d %H:%M") -- Update datetime directly in template_values

	-- Replace placeholders in the template
	for key, value in pairs(template_values) do
		template_content = template_content:gsub("{" .. key .. "}", value)
	end

	local dest_file = io.open(dest_path_with_filename, "w")
	if dest_file then
		dest_file:write(template_content)
		dest_file:close()
	end
	vim.cmd("e " .. dest_path_with_filename)
	vim.bo.filetype = "markdown" -- Consider inferring filetype from the file extension
end

---@param template_file string -- The template file name within the templates directory
---@param template_values table<string, string> -- Table containing the values to fill out the template
M.insert_template_into_current_buffer = function(template_file, template_values)
	-- Load template function
	local function load_template(template_path)
		local tmp_file, err = io.open(template_path, "r")
		if not tmp_file then
			print("Error loading template: " .. err)
			return nil
		end
		local content = tmp_file:read("*all")
		tmp_file:close()
		return content
	end

	local template_path = M.config.template_dir .. template_file
	local template_content = load_template(template_path)
	if not template_content then
		return -- Template loading failed
	end

	-- Add dynamic values to template_values
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.datetime = os.date("%Y-%m-%d %H:%M") -- Current date and time
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.date = os.date("%Y-%m-%d") -- Current date
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.time = os.date("%H:%M") -- Current time
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.id = short_uuid() -- Unique ID
	---@diagnostic disable-next-line: assign-type-mismatch
	template_values.user = os.getenv("USER") -- Current system user

	-- Replace placeholders in the template
	for key, value in pairs(template_values) do
		template_content = template_content:gsub("{" .. key .. "}", value)
	end

	-- Insert the processed template content into the current buffer
	local current_line, _ = unpack(vim.api.nvim_win_get_cursor(0)) -- Get the current cursor line
	local lines = vim.split(template_content, "\n") -- Split the template content into lines
	vim.api.nvim_buf_set_lines(0, current_line, current_line, false, lines) -- Insert lines at the current cursor position
end

return M
