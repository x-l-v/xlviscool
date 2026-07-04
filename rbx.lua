if game:GetService('RunService'):IsStudio() then 
	Instance.new('ScreenGui',game.Players.LocalPlayer.PlayerGui).Name = 'RobloxGui'; -- idk why but library need it
end;

return function(func)
	local SFake = setmetatable({},{
		__index = function(self , i)
			warn('d',i)
		end,
	});

	local newUIFake = function()
		return setmetatable({},{
			__index = function(self , i)
				warn('UI Need',i)
			end,
		});
	end

	local exploitEnv = {
		'writefile',
		'dofile',
		'readfile',
		'isfolder',
		'isfile',
		'makefolder',
		'loadfile'
	};

	local OldEnv = getfenv();
	local instanceFake = {};

	local fakeFileSystem = {};

	local blank = function(...)
		return ...
	end;

	instanceFake.game = setmetatable({},{
		__index = function(self , i)
			local clData = game[i];

			if typeof(clData) == 'function' then
				return function(self , a)
					if a == 'CoreGui' then
						return game:GetService('Players').LocalPlayer.PlayerGui; -- change from CoreGui to PlayerGui
					end;

					return clData(game,a);
				end;
			end;

			return clData
		end,	
		__newindex = function(self , i,v)
			game[i] = v
		end,
	});	

	setfenv(func,setmetatable(instanceFake,{
		__index = function(self,i)
			if i == 'cloneref' then
				return function(a)
					return a;
				end;
			end;

			if i == 'loadstring' then
				return function(src)
					if string.find(src,[[return setfenv(function(...) return OVHohHsO(...) end, setmetatable({ ["OVHohHsO"] = ... }, { __index = getfenv((...)) }))]],1,true) then
						return function(...)
							setfenv(function(...) return OVHohHsO(...) end, setmetatable({ ["OVHohHsO"] = ... }, { __index = getfenv((...)) }));
						end
					end;

					return loadstring(src);
				end
			end;

			if i == 'isfolder' or i == 'isfile' then
				return function(a)
					return fakeFileSystem[a]	
				end
			end;

			if i == "makefolder" or i == "writefile" then
				return function(a,conent)
					fakeFileSystem[a] = conent;	
					return true
				end
			end;

			if i == 'readfile' then
				return "{}"
			end;

			if table.find(exploitEnv,i) then
				return blank;
			end;

			if i == 'getgenv' then
				return function()
					return OldEnv
				end
			end;

			if not OldEnv[i] then

				if i == 'tablein' then --- Env name by sofia 100% (fucking shit)
					return table.insert; 
				end

				if i == 'Config' then
					return {};
				end;

				if i == 'Util' then
					return SFake;
				end;

				if i == 'Connections' then
					return SFake;
				end;
			end;

			return OldEnv[i];
		end,

		__newindex = function(self , i , v)
			rawset(OldEnv,i,v);
		end,
	}))
end
