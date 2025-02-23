----------------------------- Pulling Essentials --------------------------------------
local VorpInv = {}
VorpInv = exports.vorp_inventory:vorp_inventoryApi()
local VORPcore = {}
TriggerEvent("getCore", function(core)
  VORPcore = core
end)

------------------------ Handles Giving Player Items when hunt over -----------------------
RegisterServerEvent('bcc:legendaries:giveitemsbear')
AddEventHandler('bcc:legendaries:giveitemsbear', function(Rewards)
  for k, v in pairs(Rewards) do
    VorpInv.addItem(source, v.name, v.count)
  end
  if Config.LevelSystem == true then                                                                        --if config level system set true then
    local Character = VORPcore.getUser(source)
        .getUsedCharacter                                                                                   --checks the char used
    local charidentifier = Character
        .charIdentifier                                                                                     --This is the static id of your character
    local levelin = Config
        .LevelIncreaseperHunt                                                                               --Sets the variable to the config amount
    local identifier = Character
        .identifier                                                                                         --steam id
    local param = { ['charidentifier'] = charidentifier,['identifier'] = identifier,['levelin'] = levelin } --sets params for exmysql
    exports.oxmysql:execute(
      'UPDATE legendaries SET `trust`=trust+@levelin WHERE charidentifier=@charidentifier AND identifier=@identifier',
      param) --Adds plus 1 to trust, in the table where the char id and id match the players char id and id
  end
  VORPcore.NotifyBottomRight(source, Config.Language.AnimalSkinned, 4000)
end)

--------------------- Cooldown Setup ------------------------------------------------
local cooldown = false --sets the check to false on server start
RegisterServerEvent('bcc:legendaries:menuopen5')
AddEventHandler('bcc:legendaries:menuopen5', function(Cost)
  local Character = VORPcore.getUser(source).getUsedCharacter
  if cooldown == false then
    Character.removeCurrency(0, Cost)
    TriggerClientEvent('bcc:legendaries:menuopen4', source, arg)
    cooldown = true
    Wait(GlobalHuntCooldown)
    cooldown = false
  elseif cooldown == true then
    TriggerClientEvent('bcc:legendaries:failmenuopen', source)
  end
end)

---------------------------------------- TESTING DATABASE --------------------------------------------------

--------- This will create the bcc:legendaries table on script launch if it does not already exist -----------------
-------Pulled from bcc:pets and modified ----------------------
Citizen.CreateThread(function()
  --Using oxmysql to create the table if its not already made every time script is launched
  if Config.LevelSystem == true then --if level system is true then
    exports.oxmysql:execute([[CREATE TABLE if NOT EXISTS `legendaries` (
      `identifier` varchar(50) NOT NULL, /*Creates a tab in the table for ident*/
      `charidentifier` int(11) NOT NULL,
      `trust` int(100) NOT NULL DEFAULT 0,
      UNIQUE KEY `identifier` (`identifier`))
    ]])
  end
end)

--------- Checks if you exist in the DB, and if you do not it adds you to the DB aswell as adds 1 to your trust level----------------
RegisterServerEvent('bcc:legendaries:DBCheck')
AddEventHandler('bcc:legendaries:DBCheck', function()
  local _source = source
  local Character = VORPcore.getUser(_source).getUsedCharacter --checks the char used
  local charidentifier = Character.charIdentifier              --This is the static id of your character
  local identifier = Character.identifier                      --steam id
  local param = { ['charidentifier'] = charidentifier,['identifier'] = identifier }
  --------The if you exist in db code was pulled from vorp_banking and modified ----------------
  exports.oxmysql:execute(
    "SELECT identifier, charidentifier FROM legendaries WHERE identifier = @Playeridentifier AND charidentifier = @CharIdentifier",
    { ["@Playeridentifier"] = identifier,["CharIdentifier"] = charidentifier },
    function(result)                                                                                                 --Checks if you exist in the database
      if result[1] then                                                                                              --This will run if your char id or player id is in the db already
        --Player already exists do nothing
      else                                                                                                           --this will run if you do not exist in the db(adds your char id and player id to the database)
        exports.oxmysql:execute(
          "INSERT INTO legendaries ( `charidentifier`,`identifier` ) VALUES ( @charidentifier,@identifier )", param) --If player is not in db this will create him in the db
      end
    end)
end)

------------------This will output your level inside the trust variable --------------------------------------------
RegisterServerEvent('bcc:legendaries:GetTrustLevel')
AddEventHandler('bcc:legendaries:GetTrustLevel', function()
  local _source = source
  local Character = VORPcore.getUser(_source).getUsedCharacter --checks the char used
  local charidentifier = Character.charIdentifier              --This is the static id of your character
  local identifier = Character.identifier                      --steam id
  local param = { ['charidentifier'] = charidentifier,['identifier'] = identifier }
  exports.oxmysql:execute(
    "SELECT trust FROM legendaries WHERE charidentifier=@charidentifier AND identifier=@identifier", param,
    function(result)
      local trust = result[1]
          .trust                                                             --This is the trust variable from the database
      TriggerClientEvent('bcc:legendaries:ClientLevelCatch', _source, trust) --passes trust to client
    end)
end)
