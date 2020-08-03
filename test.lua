local a = {
    a = 'a'
}

function a:test ()
    self:print()
end

function a:print ()
    print(self.a)
end

a['test']()