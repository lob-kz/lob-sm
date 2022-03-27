static TopMenu topMenuOptions;
static TopMenuObject catCompletion;
static TopMenuObject itemsCompletion[COMPLETIONOPTION_COUNT];

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (topMenuOptions == topMenu && catCompletion != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catCompletion = topMenu.AddCategory(LOB_COMPLETION_CATEGORY, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (catCompletion == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (topMenuOptions == topMenu)
	{
		return;
	}
	
	topMenuOptions = topMenu;
	
	for (int option = 0; option < view_as<int>(COMPLETIONOPTION_COUNT); option++)
	{
		itemsCompletion[option] = topMenuOptions.AddItem(gC_CompletionOptionNames[option], TopMenuHandler_Completion, catCompletion);
	}
}

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == catCompletion)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Completion", param);
		}
	}
}

public void TopMenuHandler_Completion(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	CompletionOption option = COMPLETIONOPTION_INVALID;
	for (int i = 0; i < view_as<int>(COMPLETIONOPTION_COUNT); i++)
	{
		if (topobj_id == itemsCompletion[i])
		{
			option = view_as<CompletionOption>(i);
			break;
		}
	}
	
	if (option == COMPLETIONOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case CompletionOption_ChatTag:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_CompletionOptionPhrases[option], param,
					gC_CompletionChatTagPhrases[GOKZ_GetOption(param, gC_CompletionOptionNames[option])], param);
			}
			case CompletionOption_ChatColor:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_CompletionOptionPhrases[option], param,
					gC_CompletionChatColorPhrases[GOKZ_GetOption(param, gC_CompletionOptionNames[option])], param);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, gC_CompletionOptionNames[option]);
		topMenuOptions.Display(param, TopMenuPosition_LastCategory);
	}
}
