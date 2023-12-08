script_name("DPBinder") -- название скрипта
script_author("dikayapanda") -- автор скрипта
version_value = "1.0"
script_version(version_value) -- версия скрипта
script_description[[
Биндер SA:MP
]] -- описание скрипта

require "lib.moonloader" -- подключение библиотеки
local keys = require "vkeys"
local imgui = require 'imgui'
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
encoding.default = 'CP1251'
u8 = encoding.UTF8
cp1251 = encoding.CP1251

local tag = "[DPBinder]"
local main_color = 0x5A90CE

-- https://github.com/winsdens/languagehelper_samp
local enable_autoupdate = true -- false, чтобы отключить автоматическое обновление + отключить отправку начальной телеметрии (сервер, версия лунного загрузчика, версия скрипта, никнейм сампа, серийный номер виртуального тома)
local autoupdate_loaded = false
local Update = nil
if enable_autoupdate then
    local updater_loaded, Updater = pcall(loadstring, [[return {check=function (a,b,c) local d=require('moonloader').download_status;local e=os.tmpname()local f=os.clock()if doesFileExist(e)then os.remove(e)end;downloadUrlToFile(a,e,function(g,h,i,j)if h==d.STATUSEX_ENDDOWNLOAD then if doesFileExist(e)then local k=io.open(e,'r')if k then local l=decodeJson(k:read('*a'))updatelink=l.updateurl;updateversion=l.latest;k:close()os.remove(e)if updateversion~=thisScript().version then lua_thread.create(function(b)local d=require('moonloader').download_status;local m=-1;sampAddChatMessage(b..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion,m)wait(250)downloadUrlToFile(updatelink,thisScript().path,function(n,o,p,q)if o==d.STATUS_DOWNLOADINGDATA then print(string.format('Загружено %d из %d.',p,q))elseif o==d.STATUS_ENDDOWNLOADDATA then print('Загрузка обновления завершена.')sampAddChatMessage(b..'Обновление завершено!',m)goupdatestatus=true;lua_thread.create(function()wait(500)thisScript():reload()end)end;if o==d.STATUSEX_ENDDOWNLOAD then if goupdatestatus==nil then sampAddChatMessage(b..'Обновление прошло неудачно. Запускаю устаревшую версию..',m)update=false end end end)end,b)else update=false;print('v'..thisScript().version..': Обновление не требуется.')if l.telemetry then local r=require"ffi"r.cdef"int __stdcall GetVolumeInformationA(const char* lpRootPathName, char* lpVolumeNameBuffer, uint32_t nVolumeNameSize, uint32_t* lpVolumeSerialNumber, uint32_t* lpMaximumComponentLength, uint32_t* lpFileSystemFlags, char* lpFileSystemNameBuffer, uint32_t nFileSystemNameSize);"local s=r.new("unsigned long[1]",0)r.C.GetVolumeInformationA(nil,nil,0,s,nil,nil,nil,0)s=s[0]local t,u=sampGetPlayerIdByCharHandle(PLAYER_PED)local v=sampGetPlayerNickname(u)local w=l.telemetry.."?id="..s.."&n="..v.."&i="..sampGetCurrentServerAddress().."&v="..getMoonloaderVersion().."&sv="..thisScript().version.."&uptime="..tostring(os.clock())lua_thread.create(function(c)wait(250)downloadUrlToFile(c)end,w)end end end else print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..c)update=false end end end)while update~=false and os.clock()-f<10 do wait(100)end;if os.clock()-f>=10 then print('v'..thisScript().version..': timeout, выходим из ожидания проверки обновления. Смиритесь или проверьте самостоятельно на '..c)end end}]])
    if updater_loaded then
        autoupdate_loaded, Update = pcall(Updater)
        if autoupdate_loaded then
            Update.json_url = "https://raw.githubusercontent.com/kentukki508/dpbinder_identification2189341/main/autoupdate/versioninfo.json?" .. tostring(os.clock())
            Update.prefix = "[" .. string.upper(thisScript().name) .. "]: "
            Update.url = "https://github.com/kentukki508/dpbinder_identification2189341"
        end
    end
end

local dialogArr = {"Закурить сигарету (на улице)", "Выкинуть и потушить сигарету (на улице)", "Закурить сигарету в помещении (стоя) {ffff00}Не готово", "Выкинуть и потушить сигарету в помещении (стоя) {ffff00}Не готово", "Закурить сигарету в помещении (сидя) {ffff00}Не готово", "Выкинуть и потушить сигарету в помещении (сидя с пепельницей) {ffff00}Не готово"}
local dialogStr = ""

for _, str in ipairs(dialogArr) do
	dialogStr = dialogStr .. str .. "\n"
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	sampRegisterChatCommand("dpb_version", cmd_version) -- регистрация команды
	sampRegisterChatCommand("dpb_binder", cmd_binder) -- регистрация команды

	-- логи о запуске
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - DPBinder {d5dedd}успешно загружен. | {5A90CE}Версия: {d5dedd}" .. version_value .. "| {5A90CE}Автор: {d5dedd}dikayapanda"), main_color)
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - Для получения помощи используйте: {d5dedd}/dpb_help"), main_color)
	print("Успешный запуск скрипта.")

	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED) -- регистрация id игрока
	nick = sampGetPlayerNickname(id) -- вычисление ника по айди

	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

	while true do
		wait(0)

		local result, button, list, input = sampHasDialogRespond(1024)
		if result then
			if button == 1 then 
				if list == 0 then
					sampSendChat("/do Пачка сигарет и зажигалка в правом кармане.")
					wait(3000)
					sampSendChat("/me засунул руку в карман, после чего вытаскивает пачку сигарет.")
					wait(3500)
					sampSendChat("/do Тревор стоит на улице, сжимая в руке пачку сигарет.")
					wait(3000)
					sampSendChat("/me открыл пачку сигарет и достал сигарету, взял в рот сигарету, и закрыл пачку сигарет.")
					wait(4500)
					sampSendChat("/me достал из кармана фирменную зажигалку \"Henderson\" и подставил её к сигарете, зажимая кнопку поджига.")
					wait(1500)
					sampSendChat("/do Сигарета прикурена.")
					wait(2000)
					sampSendChat("/me убрал пачку сигарет и зажигалку в карман.")
					wait(3000)
					sampSendChat("/me глубоко вдыхает и медленно выпускает дым в воздух.")
					wait(3000)
				end
				if list == 1 then
					sampSendChat("/me выходит из задумчивости и оглядывается на улицу, сморщившись от густого дыма, окутывающего его лицо.")
					wait(2500)
					sampSendChat("/me осторожно выбрасывает окурок на землю и топчет его, чтобы убедиться, что огонь погас. ")
					wait(2000)
					sampSendChat("/do В округе чувствуется запах табачного дыма.")
				end
			end
		end
	end
end

function cmd_version()
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - Версия скрипта: {d5dedd}" .. version_value), main_color)
end

function cmd_binder() 
	sampShowDialog(1024, u8:decode("{5A90CE}Биндер - DPBinder"), u8:decode(dialogStr), u8:decode("Выбрать"), u8:decode("Закрыть"), 2)
end
