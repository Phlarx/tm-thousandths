namespace FixUI {
	uint oldLength = 0;
	
	void Turbo() {
		if(GetApp().Network is null || GetApp().Network.ClientManiaAppPlayground is null){
			return;
		}
		auto playground = GetApp().Network.ClientManiaAppPlayground;
		
		//Only fix UI if the UI changed
		if(playground.UILayers.Length != oldLength){
			for(uint i = 0; i < playground.UILayers.Length; ++i) 
			{
				auto layer = cast<CGameUILayer>(playground.UILayers[i]);

				while(Regex::Contains(layer.ManialinkPage, "posn=\"74\\.")) {
					layer.ManialinkPage = Regex::Replace(layer.ManialinkPage, "posn=\"74\\.6725", "posn=\"69.6725"); // 100
					layer.ManialinkPage = Regex::Replace(layer.ManialinkPage, "posn=\"81\\.6725", "posn=\"76.6725"); //     -
					layer.ManialinkPage = Regex::Replace(layer.ManialinkPage, "posn=\"88\\.6725", "posn=\"83.6725"); //       100
					print('replaced');
				}
			}
			
			oldLength = playground.UILayers.Length;
		}
	}
}
