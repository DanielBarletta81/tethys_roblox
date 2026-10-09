--!strict
local Grid=require(if script then script.Parent.ChunkGrid else "./ChunkGrid")
local Codec=require(if script then script.Parent.VoxelCodec else "./VoxelCodec")
local Text=require(if script then script.Parent.Base64 else "./Base64")
local Capture=require(if script then script.Parent.Capture else "./Capture")
local Session={};Session.__index=Session
function Session.new(backend: any): any
	return setmetatable({Backend=backend,Busy=false,Generation=0,Last=nil},Session)
end
function Session.Cancel(self: any)
	self.Generation+=1;self.Last=nil
end
local function operation(self: any,fn: ()->any): any
	assert(not self.Busy,"A Stratum operation is already running")
	assert(self.Backend.IsEditMode(),"Stratum authoring requires Edit mode")
	self.Busy=true
	local ok,result=pcall(fn)
	self.Busy=false
	assert(ok,tostring(result))
	return result
end
function Session.Preview(self: any,bounds: any,progress: ((number,number)->())?): any
	return operation(self,function()
		self.Last=nil
		local start,generation=os.clock(),self.Generation
		local plan=Grid.Plan(bounds)
		local capture={Bounds=table.clone(bounds),Chunks={}}
		for i,b in ipairs(plan) do
			assert(self.Generation==generation and self.Backend.IsEditMode(),"Capture cancelled")
			local data=Codec.Encode(self.Backend.Read(b))
			table.insert(capture.Chunks,{Bounds=b,Data=data,Text=Text.Encode(data)})
			if progress then progress(i,#plan) end
			self.Backend.Yield()
		end
		assert(self.Generation==generation and self.Backend.IsEditMode(),"Capture cancelled")
		capture.Stats=Capture.Validate(capture);capture.Stats.CaptureSeconds=os.clock()-start
		self.Last=capture
		return capture
	end)
end
function Session.Publish(self: any): any
	return operation(self,function()
		local capture,generation=self.Last,self.Generation
		assert(capture,"Preview a bounded selection before saving")
		Capture.Validate(capture)
		-- Let queued cancellation/edit input run before the final bounded scan.
		self.Backend.Yield()
		assert(self.Generation==generation and self.Backend.IsEditMode(),"Save cancelled")
		-- Do not yield between rechecks: an earlier chunk could otherwise be
		-- edited while a later one is verified, then quietly archived as current.
		for _,record in ipairs(capture.Chunks) do
			assert(self.Generation==generation and self.Backend.IsEditMode(),"Save cancelled")
			local now=Codec.Encode(self.Backend.Read(record.Bounds))
			assert(buffer.tostring(now)==buffer.tostring(record.Data),"Terrain changed; preview the selection again")
		end
		assert(self.Generation==generation and self.Backend.IsEditMode(),"Save cancelled")
		return self.Backend.Publish(capture)
	end)
end
return Session
