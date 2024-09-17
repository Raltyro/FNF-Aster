function love.conf(t)
	t.version = "12.0"
	t.identity = "FNF-Aster"
	t.console = true
	t.gammacorrect = false
	t.highdpi = false

	-- In Mobile, it's Vulkan
	--t.renderers = {"vulkan"}
	t.renderers = {"metal", "opengl"}

	-- we'll initialize the window later in the code
	t.modules.window = false
	t.modules.physics = false
	t.modules.touch = false
	t.modules.video = false
end

return {
	title = "Funkin' Aster",
	width = 1280,
	height = 720,

	debug = true
}