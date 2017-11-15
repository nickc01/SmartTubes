function init()
	message.setHandler("SetPosition", function(_,_,pos)
		mcontroller.setPosition(pos);
	end);
	message.setHandler("Destroy", function()
		projectile.die();
	end);
	message.setHandler("Refresh",function()
		projectile.setTimeToLive(1);
	end);
end