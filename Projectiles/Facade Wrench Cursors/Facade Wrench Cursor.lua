function init()
	message.setHandler("SetPosition", function(_,_,pos)
		mcontroller.setPosition(pos);
	end);
	message.setHandler("Destroy", function()
		projectile.die();
	end);
end