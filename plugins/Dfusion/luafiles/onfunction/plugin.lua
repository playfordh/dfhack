onfunction=onfunction or {}
function onfunction.install()
	ModData=engine.installMod("dfusion/onfunction/functions.o","functions",4)
	modpos=ModData.pos
	modsize=ModData.size
	onfunction.pos=modpos
	trgpos=engine.getpushvalue()
	print(string.format("Function installed in:%x function to call is: %x",modpos,trgpos))
	local firstpos=modpos+engine.FindMarker(ModData,"function")
	engine.poked(firstpos,trgpos-firstpos-4) --call Lua-Onfunction
	onfunction.fpos=modpos+engine.FindMarker(ModData,"function3")
	engine.poked(modpos+engine.FindMarker(ModData,"function2"),modpos+modsize)
	engine.poked(onfunction.fpos,modpos+modsize)
	SetExecute(modpos)
	onfunction.calls={}
	onfunction.functions={}
	onfunction.names={}
end
function OnFunction(values)
	--[=[print("Onfunction called!")
	print("Data:")
	for k,v in pairs(values) do
		print(string.format("%s=%x",k,v))
	end
	print("stack:")
	for i=0,3 do 
		print(string.format("%d %x",i,engine.peekd(values.esp+i*4)))
	end
	--]=]
	if onfunction.functions[values.ret] ~=nil then
		onfunction.functions[values.ret](values)
	end
	
	return  onfunction.calls[values.ret] --returns real function to call
end
function onfunction.patch(addr)
	
	if(engine.peekb(addr)~=0xe8) then
		error("Incorrect address, not a function call")
	else
		
		onfunction.calls[addr+5]=addr+engine.peekd(addr+1)+5 --adds real function to call
		engine.poked(addr+1,engine.getmod("functions")-addr-5)
	end
end
function onfunction.AddFunction(addr,name)
	onfunction.patch(addr)
	onfunction.names[name]=addr+5
end
function onfunction.SetCallback(name,func)
	if onfunction.names[name]==nil then
		error("No such function:"..name)
	else
		onfunction.functions[onfunction.names[name]]=func
	end
end
mypos=engine.getmod("functions")
function DeathMsg(values)
	name=engine.peek(values.edi,ptt_dfstring)
	print(name:getval().." died")
end
if mypos then
	print("Onfunction already installed")
	--onfunction.patch(0x189dd6+offsets.base())
else
	onfunction.install()
	onfunction.AddFunction(0x55499D+offsets.base(),"Move") --on creature move found with "watch mem=xcoord"
	onfunction.AddFunction(0x275933+offsets.base(),"Die")  --on creature death? found by watching dead flag then stepping until new function
	onfunction.SetCallback("Die",DeathMsg)
end