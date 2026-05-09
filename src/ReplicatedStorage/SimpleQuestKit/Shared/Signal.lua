local Signal = {}
Signal.__index = Signal

function Signal.new()
    return setmetatable({ _callbacks = {} }, Signal)
end

function Signal:Connect(callback)
    table.insert(self._callbacks, callback)
    return {
        Disconnect = function()
            for index, storedCallback in ipairs(self._callbacks) do
                if storedCallback == callback then
                    table.remove(self._callbacks, index)
                    break
                end
            end
        end,
    }
end

function Signal:Fire(...)
    for _, callback in ipairs(self._callbacks) do
        task.spawn(callback, ...)
    end
end

return Signal
