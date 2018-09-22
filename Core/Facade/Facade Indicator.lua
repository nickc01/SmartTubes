



function init()
	message.setHandler("Destroy", function()
		projectile.die();
	end);
	message.setHandler("Refresh",function()
		projectile.setTimeToLive(3);
	end);
end
