--!strict
--!optimize 2
--!native

--[[
    ALLURE META-FRAMEWORK
    By r_iva9

    API

    Types

    ...

    Functions

    ...
]]

--[[ () -> (A, B) ---> T{A | B} ]]
type function _pack(A: type)
	local indexedTypes: { [any]: type } = A:returns().head :: { [number]: type }
    local t = types.newtable()

    --WARNING: THIS LINE PREVENTS THE TYPESOLVER FROM CRASHING DUE TO TYPE FUNCTION RECURSION!
    if not indexedTypes or #indexedTypes == 0 then return t end

	local valueType = types.unionof(unpack(indexedTypes))

	t:setindexer(types.number, valueType) --unpack(indexedTypes) :: type))

	return t
end

--[[ T{A | B} ---> (A, B) ]]
type function _unpack(A: type)
	return (A:indexer() :: any).readresult :: any
end

--[[ (A, B) ---> T{A | B} ]]
type pack<P...> = _pack<() -> P...>

--[[ () -> (A, B) ---> () -> (Package<A> | Package<B>) ]]
type function _Dependency_pack_function(A: type)
	local indexedTypes: { type } = A:returns().head :: { type }

    --WARNING: THIS LINE PREVENTS THE TYPESOLVER FROM CRASHING DUE TO TYPE FUNCTION RECURSION!
    if not indexedTypes or #indexedTypes == 0 then return A end

	for key, type0 in indexedTypes do
        --Allure claims dependencies of package dependencies to be none, otherwise would meet squared type packs and typesolver crashes
        --Only contents matter
		indexedTypes[key] = Package(type0)
	end

	local f = types.newfunction()
	f:setparameters(indexedTypes)
	f:setreturns(indexedTypes)

	return f
end

-- Luau obliges to create this object otherwise I literally cannot use the type function lol
local _: _Dependency_pack_function<() -> (nil, nil)>

type _Dependency_pack<P...> = _Dependency_pack_function<() -> P...>
type DEPENDENCIES<P...> = _pack<_Dependency_pack_function<() -> P...>>

--local b: DEPENDENCIES<{a: number}, {a: string}> = {{a = 1} :: Package<{a: number}>, {a = "text"} :: Package<{a: string}>}
-- local pack: Package<{test: number}, {a: number}> = {} :: any

export type function tablemerger(T: type, V: type)
    local t = types.newtable()

    for k, v in T:properties() do
        t:setproperty(k, v.read)
    end
    for k, v in V:properties() do
        t:setproperty(k, v.read)
    end

    return t
end

--[[
    the technical type that turns tuples into unions is done
    you can use it to make a function that does intersections or merges each item with something

    you right now need a type for dependencies
    with metadata

    idea:

    > local dependency1, dependency2 = Allure:Package(Name, {Dependency1, Dependency2}, priority?)
    < [ERROR: ALLURE] Cannot create package "Name": Cyclic dependency detected (Dependency1 --> Name)

    creating a new package (like npm, wally) then register it into the dependency tree
    in the tree it is linked to branches of dependencies forming a tree for each package
    (which makes it easier to)

    these packages are registered right when they are required so it's no problem

    then you need a way to inject the table into the package (register it; like you create a new package with dependencies given and then register it)

    PROGRESS:

    THE PACKAGE TYPING IS DONE!
    For example Package<{}, {}, {}>
    The first list is the contents of the package, second is the content of the first dependency, third is the content of the second dependency;
    AS MANY DEPENDENCIES as you want

    Allure:Package(dep1, dep2) {
        Name = "script name default",
        Type = "Framework", --default to provider
        Version = {1, 0, 0} --becomes read-only and assigns keys major, minor, patch
        PATH = "/Folder/" --/ by default, allows loading in groups but when listing dependencies the first / is unneeded
        --^^^ might be scrapped if cant return the content type
    }

    tr = Allure:DependencyTree()
    tr:ApplyDescendants(fn)
    tr:LoadDescendants(predicateFn)
]]

-- Utility type that fills the luau table type blank
type table = {[any]: any}

--[[
    Unregistered package type with customizable metadata.
    <br>This object assists with creating and modifying a package that is about to be registered.

    Format: UnregisteredPackage\<Content>
    <br>The created Dependencies inside of the type lists dependencies context turned into packages each
]]
export type UnregisteredPackage<T> = setmetatable<T, {
    __packageref: T,
    __index: {
        UseDependency: <S, M>(self: S, singleton: M) -> M,
        SetPriority: <S>(self: S, priority: number) -> S,
        ModifyMeta: <S>(self: S, override: table) -> S
    }
}>

--[[
    Registered package type with readonly metadata.
    <br>Registered packages can be used as Dependencies for other packages.

    Format: Package\<Content>
]]
export type Package<T> = T & {
    read Name: string,
    read Version: string,
    read Description: string,

	read Dependencies: { Package<unknown> },
    read Priority: number,

	--[[ Decides whether the client can require() the package or have it as a dependency ]]
	read Client: boolean,
}

local REGISTERED: {[string]: unknown}

--T is the metadata; Content = {}
--Returns the package and a tail of dependency packages
--type PackageConstructor = <A, B, C, D, E, F, G, H, I, J, K, L, M, 
--    N, O, P, Q, R, S, T, U, V, W, X, Y, Z>(...string) -> <T, Name>(T & {Name: Name | "", [string]: any?}) -> (Package<T, Name>)--, _unpack<DEPENDENCIES<A, B, C, D, E, F, G, H, I, J, K, L, M, 
    --N, O, P, Q, R, S, T, U, V, W, X, Y, Z>>)

--Replaces package content type
--type PackageRegister = <T, Name>(Package<any, Name>, T, number?) -> (Package<T, Name>, typeof(REGISTERED) & {[Name]: Package<T>})


	--[[ Creates an ActorPool and a Master giving the task for consumption of the actor with lowest workload ]]
	--ActorPool: number?,
	--ActorQueryLimit: number?,

	--[[ Unreleased ]]
	--ActorErrorHook: (...any) -> ...any?,
	--ActorTimeoutHook: (number) -> (...any) -> ...any?,
	--ActorMaster: (...any) -> ...any?,


--[[



--[[ 

//// CONTENT 


local Allure = {}

REGISTERED = {} :: any

--Low level table merger function
--They match key and value types
local function lowMerge<K, V>(t0: {[K]: V}, t1: {[K]: V}): {[K]: V}
    for k,v in t1 do
        t0[k] = v
    end
    return t0
end

--Low level table merger function that merges only non-shared keys
local function exceptionalLowMerge<K, V>(t0: {[K]: V}, t1: {[K]: V}): {[K]: V}
    for k,v in t1 do
        t0[k] = t0[k] or v
    end
    return t0
end

local function tableToVersion(t0: {[number]: number})
    return {
        Major = t0[1],
        Minor = t0[2],
        Patch = t0[3]
    }
end

local function singleton<T>(val: T | ""): T
    return val
end

local PackageConstructor: PackageConstructor = function<A, B, C, D, E, F, G, H, I, J, K, 
    L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z>(...: string)
    local dep: any = {...}
    for k, v in dep do
        dep[k] = REGISTERED[v]
    end

    local depcontents = {}
    for i=1, 26 do
        depcontents[i] = dep[i] or nil
    end
    
    -- !!!!
    --remove all of these ABCD and keep Dependencies generic
    --then do index<> on it
    --remember keyof<> too

    local a: A, b: B, c: C, d: D, e: E, f: F, g: G, h: H, i: I, j: J, k: K, l: L, 
          m: M, n: N, o: O, p: P, q: Q, r: R, s: S, t: T, u: U, v: V, w: W, x: X, y: Y, z: Z = table.unpack(depcontents)

    local D: DEPENDENCIES<typeof(a), typeof(b), typeof(c), typeof(d), typeof(e), typeof(f), typeof(g), typeof(h), typeof(i), 
                              typeof(j), typeof(k), typeof(l), typeof(m), typeof(n), typeof(o), typeof(p), typeof(q), typeof(r), 
                              typeof(s), typeof(t), typeof(u), typeof(v), typeof(w), typeof(x), typeof(y), typeof(z)> = dep

    return function<T, Name>(meta: T & {Name: Name | "", [string]: any})
        
        local self: Package<T> = exceptionalLowMerge(meta, {
            Name = script.Name,
            Version = tableToVersion(meta.Version or {1, 0, 0}),
            Dependencies = D,
            Type = "Provider",
            Priority = 0,

            Client = true
        })

        return self
    end
end :: PackageConstructor

local PackageRegister: PackageRegister = function<P, T>(pack: Package<P>, content: T & { }, priority: number?)
    pack = lowMerge(pack :: T, content) :: any
    REGISTERED[pack.Name :: typeof(pack.Name)] = pack :: Package<T>

    local REGISTERED2 = (REGISTERED :: typeof(REGISTERED) & {[typeof(pack.Name)]: Package<T>})

    return pack :: Package<{P & T}>, REGISTERED2
end :: PackageRegister

--[[
    Registers `package` -- saves it's contents under a specific name.

    Registered packages can be used as dependencies for other packages.

    ---
    @param package      `(Package)` </br> = &emsp; *The package to register.*
    @param content      `(table)` </br> = &emsp; *Contents that the package will have. Does not freeze the table.*
    @param priority      `(number?)` </br> = &emsp; *Optional amount of priority that will be added to the calculated priority.*

    @return `Package`      </br> = &emsp; *The package with assigned contents.*
]
function Allure:RegisterPackage<T>(package: Package<unknown>, content: T, priority: number?): Package<T>
    local Pack, Registered = PackageRegister(package, content, priority)

    REGISTERED = Registered
    return Pack
end

--ATTEMPTING TO CREATE & REGISTER A DEP

--local Pack = PackageConstructor() {Name = "Test"}


--[[local p, c = PackageRegister(Pack, {
    a = 10
})
REGISTERED = c

--This commented out test gives REGISTERED a good type: it has Test
]]

--[[
    So currently Name | "" works but it has to be optional somehow
    I also need to find out about dependencies type and remove the ABCD shit from constructor type

]

--Allure:RegisterPackage(Pack, {a = 10}, priority) --SOLVE THIS AND organize code

--C HAS TEST!

--local newPack, TEST = PackageConstructor("Test") {}

local b = REGISTERED["Test"]

local a: typeof(REGISTERED)


-- out of code example

local tab = {
    a = 20
}

local function test<Name, V, t>(t: t & {}, key: Name | "", val: V): t & {[Name]: V}
    t[key] = val
    return t --tab
end

local function test2<Name, V, t>(t: t & {}, key: Name | "", val: V)
    tab = test(t, key, val)
end
local tab2 = test(tab, "abc", 10)

test2(tab, "abc", 20)

local a = tab

--result: test returns the CORRECT typing that i need
--test2 doesn't do anything

]]