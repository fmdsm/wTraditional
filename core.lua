local _,ns = ...

local server = GetCVar("realmlist")
if ( server and server~="tw.logon.worldofwarcraft.com" ) then
    t.word00 = nil
    t.word0_s = nil
    t.word0_t = nil
    DEFAULT_CHAT_FRAME:AddMessage("检测到当前不是台湾服务器, 简繁转换自动停用。",1,1,0);
    return
end

local word00,word0_s,word0_t = ns.word00,ns.word0_s,ns.word0_t
local strfind,strsub,strlen,strchar,strconcat,_G = strfind,strsub,strlen,strchar,strconcat,_G
local _enable = true

local EDIT_BOXES = {
	"SendMailNameEditBox", --邮件姓名
	"SendMailSubjectEditBox", --邮件标题
	"SendMailBodyEditBox", --邮件内容
	"StaticPopup1EditBox",
	"WhoFrameEditBox",--搜索
	"MacroFrameText",--宏内容		
	"MacroPopupEditBox",--宏标题
	"BrowseName",--拍卖行
	"GuildInfoEditBox",
	"StaticPopup1WideEditBox",
	"LFGComment",--
	"TradeskillInfoInputBox",--tsi插件
	"Atr_Search_Box",--Auctionator插件
	"SkilletFilterBox",--skillet
	"FriendsFrameBroadcastInput",--战网公告
	"BagItemSearchBox",--背包搜索
	"ChatFrame1EditBox",
	--"ooxx",--这种格式 别忘了加逗号
};

local new_msg = {}
local function translator(msg)--把简体转换成繁体
	--1110xxxx 10xxxxxx 10xxxxxx 汉字
	--0xxxxxxx 字符
	if not _enable then
		return msg
	end
	local length = strlen(msg)
	local lastword
	local i = 1
	local flag, words
	while i<= length do
		local c = strbyte(msg,i)
		flag = false
		if c>=224 and c<=239 then --3字符 11100000~11101111
			-- local word = strsub(msg,i,i+5) --判断词组
			for _string in pairs(word00) do
				if strfind(msg, _string,i) == i then
					flag = true
					words = _string
					break
				end
			end
			if flag then
				tinsert(new_msg,word00[words])
				i = i + strlen(words)
			else
				local word = strsub(msg,i,i+2)
				local frame,t = strfind(word0_s,word)
				if frame then
					tinsert(new_msg,strsub(word0_t,frame,t))
				else
					tinsert(new_msg,word)
				end
				i = i + 3
			end
		elseif c == 124 then --特殊字符"|"
			local frame,t = strfind(msg,"|H%a+:.+|h.-|h",i)--"|H字母+:任意字符+|h任意字符-|h"
			if frame == i then
				tinsert(new_msg,strsub(msg,frame,t))
				i = i + t - frame + 1
			else
				tinsert(new_msg,strchar(c))
				i = i + 1
			end
		else
			tinsert(new_msg,strchar(c))
			i = i + 1
		end
	end
	local output = table.concat(new_msg)
	wipe(new_msg)
	return output
end

local BNSendWhisperSave = BNSendWhisper
local BNSendConversationMessageSave = BNSendConversationMessage
local SendChatMessageSave = SendChatMessage

function SendChatMessage(msg, type, lang, target)
	SendChatMessageSave(translator(msg), type, lang, target)
end
function BNSendConversationMessage(target,msg)
	BNSendConversationMessageSave(target,translator(msg))
end
function BNSendWhisper(id,msg)
	BNSendWhisperSave(id,translator(msg))
end

local frame = CreateFrame("Frame")
frame.flushtime = 0
local function func(self,str)
	local eb = self
	frame:SetScript("OnUpdate",function(_,elapsed)
		frame.flushtime = frame.flushtime - elapsed
		if frame.flushtime<0 then
			local pos = eb:GetCursorPosition()
			eb:SetText(translator(eb:GetText()))
			eb:SetCursorPosition(pos)
			frame.flushtime = 0
			frame:SetScript("OnUpdate",nil)
		end
	end)
end
local editbox_list = {}
local function editbox_hook()
	for i in ipairs(EDIT_BOXES) do
		if EDIT_BOXES[i]~= "ok" and _G[EDIT_BOXES[i]]then
			if _G[EDIT_BOXES[i]]:GetScript("OnChar") then--Composition
				_G[EDIT_BOXES[i]]:SetScript("OnChar",func)
			else
				_G[EDIT_BOXES[i]]:HookScript("OnChar",func)
			end
			EDIT_BOXES[i] = "ok"
		end
	end
end

frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent",function(self,event,...)
	if event == "PLAYER_LOGIN" then
		frame:RegisterEvent("ADDON_LOADED")
	end
	editbox_hook()
end)
SLASH_WTRADITIONAL1 = "/tr"

SlashCmdList["WTRADITIONAL"] = function()
	_enable = not _enable
	if _enable then
		DEFAULT_CHAT_FRAME:AddMessage("簡/繁體轉換已開啟",1,1,0)
	else
		DEFAULT_CHAT_FRAME:AddMessage("簡/繁體轉換已關閉",1,1,0)
	end
end