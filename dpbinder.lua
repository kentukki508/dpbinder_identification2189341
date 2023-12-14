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
local inicfg = require 'inicfg'
u8 = encoding.UTF8
cp1251 = encoding.CP1251

local tag = "[DPBinder]"
local main_color = 0x5A90CE

local directIni = "moonloader\\DPBinder\\dpb_binder.ini"
local mainIni = inicfg.load(nil, directIni)

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

local dialogArr = {"Закурить сигарету (на улице)", "Выкинуть и потушить сигарету (на улице)", "Закурить сигарету в помещении (стоя) {ff0000}Не готово", "Выкинуть и потушить сигарету в помещении (стоя) {ff0000}Не готово", "Закурить сигарету в помещении (сидя)", "Выкинуть и потушить сигарету в помещении (сидя с пепельницей)", "Отыгровка маски-респиратора черного цвета на лице (Обезболивающий газ)"}
local dialogStr = ""

for _, str in ipairs(dialogArr) do
	dialogStr = dialogStr .. str .. "\n"
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end

	sampRegisterChatCommand("dpb_reload", cmd_reloadscript) -- регистрация команды
	sampRegisterChatCommand("dpb_help", cmd_help) -- регистрация команды
	sampRegisterChatCommand("dpb_version", cmd_version) -- регистрация команды
	sampRegisterChatCommand("dpb_binder", cmd_binder) -- регистрация команды
	sampRegisterChatCommand("dpb_getclist", cmd_getclist) -- регистрация команды
	sampRegisterChatCommand("dpb_rpdi", cmd_rpdinfo) -- регистрация команды

	-- логи о запуске
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - DPBinder {d5dedd}успешно загружен. | {5A90CE}Версия: {d5dedd}" .. version_value .. " | {5A90CE}Автор: {d5dedd}dikayapanda"), main_color)
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - Для получения помощи используйте: {d5dedd}/dpb_help"), main_color)
	print("Успешный запуск скрипта.")

	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED) -- регистрация id игрока
	nick = sampGetPlayerNickname(id) -- вычисление ника по айди

	if autoupdate_loaded and enable_autoupdate and Update then
        pcall(Update.check, Update.json_url, Update.prefix, Update.url)
    end

	while true do
		wait(0)

		local result, button, list, input = sampHasDialogRespond(1024) -- /dpb_binder
		if result then
			--mainIni = inicfg.load(nil, directIni)

			--mainIni.config.AutorunMainWindow = 1
			--if inicfg.save(mainIni, directIni) then
			--	sampAddChatMessage(u8:decode("сохранено"), -1)
			--end

			if button == 1 then 
				if list == 0 then -- на улице 0
					sampSendChat(u8:decode("/do Пачка сигарет и зажигалка в правом кармане."))
					wait(3000)
					sampSendChat(u8:decode("/me засунул руку в карман, после чего вытаскивает пачку сигарет."))
					wait(4500)
					sampSendChat(u8:decode("/do " ..  mainIni.config.nameNominativeCase .. " стоит на улице, сжимая в руке пачку сигарет."))
					wait(4000)
					sampSendChat(u8:decode("/me открыл пачку сигарет и достал сигарету, взял в рот сигарету, и закрыл пачку сигарет."))
					wait(7000)
					sampSendChat(u8:decode("/me достал из кармана фирменную зажигалку \"Henderson\" и подставил её к сигарете, зажимая кнопку поджига."))
					wait(3500)
					sampSendChat(u8:decode("/do Сигарета прикурена."))
					wait(2000)
					sampSendChat(u8:decode("/me убрал пачку сигарет и зажигалку в карман."))
					wait(4000)
					sampSendChat(u8:decode("/me глубоко вдыхает и медленно выпускает дым в воздух."))
				end
				if list == 1 then -- на улице 1
					sampSendChat(u8:decode("/me выходит из задумчивости и оглядывается на улицу, сморщившись от густого дыма, окутывающего его лицо."))
					wait(7500)
					sampSendChat(u8:decode("/me осторожно выбрасывает окурок на землю и топчет его, чтобы убедиться, что огонь погас."))
					wait(3000)
					sampSendChat(u8:decode("/do В округе чувствуется запах табачного дыма."))
				end

				if list == 2 then -- стоя в помещении 1
					sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - {d5dedd}Эта отыгровка временно недоступна."), main_color)
				end 
				if list == 3 then -- стоя в помещении 2
					sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - {d5dedd}Эта отыгровка временно недоступна."), main_color)
				end 

				if list == 4 then -- сидя в помещении 1 
					sampSendChat(u8:decode("/me сидит в кресле, достает пачку сигарет и зажигалку из правого кармана.")) 
					wait(4500) 
					mainIni = inicfg.load(nil, directIni)
					sampSendChat(u8:decode("/do В руке у " .. mainIni.config.nameGenitiveCase .. " находится пачка сигарет.")) 
					wait(3000) 
					sampSendChat(u8:decode("/me открывает пачку сигарет и берет одну, кладет ее в рот, а затем закрывает пачку.")) 
					wait(7000) 
					sampSendChat(u8:decode("/me вынимает фирменную зажигалку \"Henderson\" из кармана и подносит ее к сигарете, нажимая кнопку поджига.")) 
					wait(2500) 
					sampSendChat(u8:decode("/do Сигарета прикурена.")) 
					wait(2000) 
					sampSendChat(u8:decode("/me возвращает зажигалку в карман.")) 
					wait(5000) 
					sampSendChat(u8:decode("/me глубоко вдыхает и медленно выпускает дым в помещение."))
					sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - {d5dedd}Здесь можно бросить пачку сигарет на стол, либо убрать в карман."), main_color)
				end

				if list == 5 then -- сидя в помещении с пепельницей 2
					sampSendChat(u8:decode("/me перестает задумываться и оглядывается по сторонам, сморщившись от густого дыма, наполняющего комнату.")) 
					wait(5500) 
					sampSendChat(u8:decode("/me тянется к пепельнице, давит её сигаретой, чтобы убедиться, что огонь погас.")) 
					wait(4000) 
					sampSendChat(u8:decode("/do В помещении чувствуется запах табачного дыма. Сигарета остаётся в пепельнице."))
				end

				if list == 6 then 
					mainIni = inicfg.load(nil, directIni)
					sampSendChat(u8:decode("/do На лице " .. mainIni.config.nameGenitiveCase .. " можно заметить черную маску-респиратор, которая...")) 
					wait(1500)
					sampSendChat(u8:decode("/do ... плотно облегает его контуры."))
					wait(5500) 
					sampSendChat(u8:decode("/do " .. mainIni.config.nameNominativeCase .. " выглядит немного загадочно, так как маска скрывает его ..."))
					wait(3500) 
					sampSendChat(u8:decode("/do ... выражение лица, но при этом добавляет некоторую привлекательность. "))
					wait(3500) 
					sampSendChat(u8:decode("/do За одеждой Тревора находятся баллоны с газовым обезболивающим препаратом."))
					wait(4500) 
					sampSendChat(u8:decode("/do Газ блокирует передачу сигналов боли в мозг."))
					
				end
			end
		end

		local result, button, list, input = sampHasDialogRespond(1026) -- /dpb_rpdi
		if result then
			if button == 1 then 
				if list == 0 then 
					--sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - {d5dedd}Эта информация временно недоступна."), main_color)
					mainIni = inicfg.load(nil, directIni)
					sampShowDialog(1027, u8:decode("{5A90CE}Информация о маске-респираторе (RP) — DPBinder"), u8:decode("{5A90CE}Информационное меню: состояние маски-респиратора с привязкой к газовым баллонам с обезболивающим\n\n1. Состояние маски-респиратора:\nДефекты маски-респератора: {d5dedd}" .. mainIni.maskresp.defectsMR .."\n{5A90CE}Включена ли маска-респиратор: {d5dedd}" .. mainIni.maskresp.turnedMR .. "\n{5A90CE}Уровень заряда аккумулятора: {d5dedd}" .. mainIni.maskresp.batteryLevelMR .. "\n{5A90CE}Статус фильтра воздуха: {d5dedd}" .. mainIni.maskresp.airFilterStatusMR .. "\n\n{5A90CE}2. Газовые баллоны с обезболивающим:\nКоличество газовых баллонов: {d5dedd}" .. mainIni.maskresp.gasCylindersMR .. "\n{5A90CE}Уровень заполненности газовых баллонов: {d5dedd}" .. mainIni.maskresp.gasCylinderFillingMR .. "\n{5A90CE}Дата следующей проверки и замены газовых баллонов: {d5dedd}" .. mainIni.maskresp.dateIaRGasCylindersMR .. "\n\n{5A90CE}3. Дополнительные опции:\nВозможность автоматического отключения маски-респиратора при неисправности баллонов: {d5dedd}" .. mainIni.maskresp.possibilityTurningOffRespitatorMalfunctionMR .. "\n{5A90CE}Запасные комплектующие и аксессуары: {d5dedd}" .. mainIni.maskresp.sparePartsMR .. "\n{5A90CE}Инструкция по использованию маски-респиратора: {d5dedd}" .. mainIni.maskresp.instructionsForUsingMR .. "\n\n{5A90CE}5. Примечание: \n{d5dedd}Данные автоматически изменяются при помощи датчика на маске-респираторе."), u8:decode("Выбрать"), u8:decode("Закрыть"), 0)
				end
			end
		end

--[[Информационное меню: состояние маски-респиратора с привязкой к газовым баллонам с обезболивающим\n\n
1. Состояние маски-респиратора:\nВключена ли маска-респиратор: [Включена/Выключена]
\nУровень заряда аккумулятора: [Высокий/Средний/Низкий/Разряжен]
\nСтатус фильтра воздуха: [Чистый/Загрязненный/Нуждается в замене]
\n\n2. Газовые баллоны с обезболивающим:
\nКоличество газовых баллонов: [Количество]
\nУровень заполненности газовых баллонов: [Высокий/Средний/Низкий/Пустой]
\nДата следующей проверки и замены газовых баллонов: [Дата]
\n\n3. Дополнительные опции:
\nВозможность автоматического отключения маски-респиратора при неисправности баллонов: [Да/Нет]
\nЗапасные комплектующие и аксессуары: [Доступны/Отсутствуют]
\nИнструкция по использованию маски-респиратора: [Доступна/Отсутствует]
\n\n4. Контактная информация:
\nТехническая поддержка: [Номер телефона]
\nСервисный центр: [Адрес и контактные данные]
\nЭкстренные случаи: [Номер телефона службы эвакуации/помощи]
\n\n5. Примечание: Пункты меню могут быть изменены и дополнены в соответствии с конкретными требованиями и особенностями маски-респиратора и газовых баллонов с обезболивающим.
]]
	end
end

function cmd_reloadscript(arg)
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - {d5dedd}Перезагружаем скрипт..."), main_color)
	thisScript():reload()
end

function cmd_help() 
	sampShowDialog(1025, u8:decode("{5A90CE}Помощь — DPBinder"), u8:decode("{5A90CE}Команды биндера:\n{5A90CE}/dpb_help - {d5dedd}получить меню помощи\n{5A90CE}/dpb_version - {d5dedd}получить информацию о версии\n{5A90CE}/dpb_binder - {d5dedd}получить меню биндера\n{5A90CE}/dpb_reload - {d5dedd}перезагрузить скрипт"), u8:decode("Выбрать"), u8:decode("Закрыть"), 0)
end

function cmd_version()
	sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - Версия скрипта: {d5dedd}" .. version_value), main_color)
end

function cmd_binder() 
	sampShowDialog(1024, u8:decode("{5A90CE}Биндер — DPBinder"), u8:decode(dialogStr), u8:decode("Выбрать"), u8:decode("Закрыть"), 2)
end

function cmd_rpdinfo() 
	sampShowDialog(1026, u8:decode("{5A90CE}Информационное меню (RP) — DPBinder"), u8:decode("Маска-респиратор с газовым обезболивающим"), u8:decode("Выбрать"), u8:decode("Закрыть"), 2)
end

function cmd_getclist(arg)
	if arg == "" then 
		sampAddChatMessage(u8:decode("{5A90CE}" .. tag .. " - Используйте команду: {d5dedd}/getclist (id)"), main_color)
	else
		player_nick = sampGetPlayerNickname(arg)

		local color = sampGetPlayerColor(arg)
		sampAddChatMessage(player_nick, color)
		--sampAddChatMessage(color, 0xFFFFFF)
	end
end
