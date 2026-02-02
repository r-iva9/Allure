--!strict
--!optimize 2
--!native

--[[
    ALLURE ACTOR METAFRAMEWORK
    By r_iva9

    API

    Types

    ...

    Functions

    ...
]]

------------
-- TYPES

-- Utility type to fill the luau table type blank
type table = { [any]: any }

-- Utility type fuction to merge 2 table types
type function Merge(a: type, b: type)
	local result = types.newtable()

	local indexer = b:indexer()
	if indexer ~= nil then
		result:setreadindexer(indexer.index, indexer.readresult)
		result:setwriteindexer(indexer.index, indexer.writeresult)
	end

	for key, prop in a:properties() do
		if prop.read ~= prop.write then
			result:setreadproperty(key, prop.read)
			result:setwriteproperty(key, prop.write)
		else
			result:setproperty(key, prop.read)
		end
	end

	for key, prop in b:properties() do
		if prop.read ~= prop.write then
			result:setreadproperty(key, prop.read)
			result:setwriteproperty(key, prop.write)
		else
			result:setproperty(key, prop.read)
		end
	end

	return result
end

-- Utility type function that lets type functions reference the table type
-- Sort of a hack
type tabler<A> = table

-- Utility type function that sets the metatable of type A to table
-- Unfortunately luau does not let us to extract the metatable basis
type function metabasis(A: type) 
	--A:setmetatable(tabler(types.any))
	return A
end

--[=[
    This is the type of unregistered containers.
	<br>However as the tables have to remain unsealed this is not used and can only assist in custom type checking.

    Format: `UnregisteredContainer<Content, Metadata>`
]=]
export type UnregisteredContainer<T, V> = setmetatable<
	T,
	{ --T & {__index: T}, {
		__containerref: T,
		__containermeta: V,
		__index: setmetatable<{
			UseDependency: <S, M>(self: S, singleton: M) -> M,
			SetPriority: <S>(self: S, priority: number) -> S,
			ModifyMeta: <S>(self: S, override: table) -> S,
		}, {__index: V}>,
	}
>

--[=[
    Registered container metadata.
    <br>Registered containers can be used as Dependencies for other containers.
]=]
export type Container = {
	read Name: string,
	read Version: string,
	read Description: string,

	read Dependencies: { unknown },
	read Priority: number,

	--[[ Decides whether the client can require() the container or have it as a dependency ]]
	read Client: boolean,
}

--[[ Creates an ActorPool and a Master giving the task for consumption of the actor with lowest workload ]]
--ActorPool: number?,
--ActorQueryLimit: number?,

--[[ Unreleased ]]
--ActorErrorHook: (...any) -> ...any?,
--ActorTimeoutHook: (number) -> (...any) -> ...any?,
--ActorMaster: (...any) -> ...any?,

--[[
    CONTENT
--]]

------------
-- UTILITY

--[[
    Utility table merger.
    <br>Takes 2 tables, modifies and returns the first one

    Does not perform cloning or deepcloning
    <br>This becomes suitable for dependencies hence the singletons
]]
function lowmerge<T, V>(t0: T, t1: V): T & V --: Merge<T, V>
	for k, v in pairs(t1) do
		(t0 :: any)[k] = v
	end
	return t0
end

--[[
    Counts all dependencies and nested dependencies within t0
]]
function depcount<T>(t0: T & { Dependencies: any? }): number
	local amount = #(t0.Dependencies or {})
	for _, dep in t0.Dependencies or {} do
		amount += depcount(dep)
	end
	return amount
end

--- Utility function to seal an unsealed table
function sealTable<T>(t: T): T
	return t
end

------------
-- ALLURE

local Allure = {}

--[=[
    Creates a workspace for container creation and modification.
    <br>Returns an unregistered container that can be registered.

    This container cannot be used in dependencies of other containers, has a utility metatable and mutable metadata.

    This is a triple function to segregate parameters and syntactic sugar.

	---

	@param ... &emsp; `(containers)` &emsp; = &emsp; *Dependency containers*
	@param -> content &emsp; `(table)` &emsp; = &emsp; *For the second function, pass the content table. This table remains unsealed*
	@param -> -> meta &emsp; `(table)` &emsp; = &emsp; *For the third function, pass the initial metadata. It is mutable before registration*
	@return `UnregisteredContainer<typeof(content), V>`      &emsp; = &emsp; *Unregistered container: a workspace for container creation with utilities*
]=]
function Allure:Container<A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S>(
	A: A?, B: B?, C: C?, D: D?, E: E?, 
	F: F?, G: G?, H: H?, I: I?, J:J?, 
	K: K?, L: L?, M: M?, N: N?, O: O?, 
	P: P?, Q: Q?, R: R?, S: S?
) --: <V>(V & table) -> (UnregisteredContainer<{}, V>, P...)
	local containers = {A, B, C, D, E, F, G, H, I, J, K, L, M, M, O, P, Q, R, S}

	return function<T>(content: T)
		(content :: any).__index = content --for classes, this remains the table unsealed

		return function<V>(meta: V & table) --: (UnregisteredContainer<{}, V>, P...)
			(content :: any).___meta = meta --this remains the table unsealed

			local container = setmetatable( --: UnregisteredContainer<{}, V>
				content,
				{
					__containerref = content,
					__containermeta = lowmerge(meta, { --modifies meta
						Dependencies = containers,
					}) :: V,
					__call = function()
						return content
					end,
					__index = setmetatable({
						UseDependency = function<S, M>(self: S, singleton: M): M
							meta.Dependencies[#meta.Dependencies + 1] = singleton
							return singleton
						end,
						SetPriority = function<S>(self: S, priority: number): S
							meta.Priority = priority
							return self
						end,
						ModifyMeta = function<S>(self: S, override: table): S
							lowmerge(meta, override)
							return self
						end,
					}, {__index = meta}), --third layer __index to reference metadata
				}
			)

			return container, A :: A, B :: B, C :: C, D :: D, E :: E, 
				F :: F, G :: G, H :: H, I :: I, J :: J, K :: K, L :: L, 
				M :: M, N :: N, O :: O, P :: P, Q :: Q, R :: R, S :: S --table.unpack(containers)
		end
	end
end

--[[
    Registers an unregistered container.
    <br>A registered container has immutable metadata, which is merged with the singleton, and can be used as a dependency.

    ---
    @param `container`      `(Unregisteredcontainer)` &emsp; = &emsp; *The unregistered container*

    @return `Container<T>`      &emsp; = &emsp; *Registered container*
]]
function Allure:Register<T, V, R>(
	container --& { __index: T, ___meta: V & { Descriptions: table? } }
) --: MetatableLess<T> --Container<T>

	--type sealedContainer = typeof(sealTable(container))

	--local containermt = getmetatable(sealTable(container))
	--containermt = containermt :: typeof(containermt)

	--type a = getmetatable<setmetatable<{}, {a: number}>>

	--type returnType = typeof(containermt.__containerref)--typeof(setmetatable({} :: sealedContainer, nil)) --metabasis<sealedContainer>

	--typesolver fails at passing argument setmetatable<>s with a base of generic T
	--so I have to retype T and V onto the metatable of `container` with correct types of references
	local containermt = getmetatable(container :: T) :: V & {__containerref: T & table & {Descriptions: table?}, __containermeta: V & table} & getmetatable<UnregisteredContainer<{}, V>>

	return lowmerge(
		lowmerge(
			--lowmerge({}, container :: T), --1. reference singleton
			container,
			{
				Name = script.Name, --2. default metadata
				Version = "1.0.0",
				Description = "",

				Dependencies = {},
				Priority = -depcount(containermt.__containermeta.Descriptions or {} :: table), --counts nested dependencies

				Client = true,
			} :: never
		),
		containermt.__containermeta :: Container
	) --3. given metadata
end

return Allure
