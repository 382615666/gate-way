local a = {}

function test ()
    print(111)
end

a['test'] = test

a:test()