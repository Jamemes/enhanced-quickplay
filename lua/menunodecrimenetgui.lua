function MenuNodeQuickplayGui:init(node, layer, parameters)
	MenuNodeQuickplayGui.super.init(self, node, layer, parameters)
	managers.menu_component:disable_crimenet()

	local mc_full_ws = managers.menu_component:fullscreen_ws()
	self._fullscreen_panel = mc_full_ws:panel():panel({
		layer = 50
	})

	self._fullscreen_panel:rect({
		alpha = 0,
		layer = 0,
		color = Color.black
	})
end