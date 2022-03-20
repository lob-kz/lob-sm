static TopMenu topMenuOptions;
static TopMenuObject catCRA;
static TopMenuObject itemsCRA[RECORDANNOUNCEOPTION_COUNT];

void OnOptionsMenuCreated_OptionsMenu(TopMenu topMenu)
{
	if (topMenuOptions == topMenu && catCRA != INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	catCRA = topMenu.AddCategory(LOB_CRA_CATEGORY, TopMenuHandler_Categories);
}

void OnOptionsMenuReady_OptionsMenu(TopMenu topMenu)
{
	// Make sure category exists
	if (catCRA == INVALID_TOPMENUOBJECT)
	{
		GOKZ_OnOptionsMenuCreated(topMenu);
	}
	
	if (topMenuOptions == topMenu)
	{
		return;
	}
	
	topMenuOptions = topMenu;
	
	// Add gokz-paint option items	
	for (int option = 0; option < view_as<int>(RECORDANNOUNCEOPTION_COUNT); option++)
	{
		itemsCRA[option] = topMenuOptions.AddItem(gC_CRAOptionNames[option], TopMenuHandler_CRA, catCRA);
	}
}

public void TopMenuHandler_Categories(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption || action == TopMenuAction_DisplayTitle)
	{
		if (topobj_id == catCRA)
		{
			Format(buffer, maxlength, "%T", "Options Menu - Cross Record Announcement", param);
		}
	}
}

public void TopMenuHandler_CRA(TopMenu topmenu, TopMenuAction action, TopMenuObject topobj_id, int param, char[] buffer, int maxlength)
{
	RecordAnnounceOption option = RECORDANNOUNCEOPTION_INVALID;
	for (int i = 0; i < view_as<int>(RECORDANNOUNCEOPTION_COUNT); i++)
	{
		if (topobj_id == itemsCRA[i])
		{
			option = view_as<RecordAnnounceOption>(i);
			break;
		}
	}
	
	if (option == RECORDANNOUNCEOPTION_INVALID)
	{
		return;
	}
	
	if (action == TopMenuAction_DisplayOption)
	{
		switch (option)
		{
			case RecordAnnounceOption_Type:
			{
				FormatEx(buffer, maxlength, "%T - %T",
					gC_CRAOptionPhrases[option], param,
					gC_AnnounceRecordTypePhrases[GOKZ_GetOption(param, gC_CRAOptionNames[option])], param);
			}
			case RecordAnnounceOption_Volume:
			{
				FormatEx(buffer, maxlength, "%T - %i%%",
					gC_CRAOptionPhrases[option], param,
					GOKZ_GetOption(param, gC_CRAOptionNames[option]) * 10, param);
			}
		}
	}
	else if (action == TopMenuAction_SelectOption)
	{
		GOKZ_CycleOption(param, gC_CRAOptionNames[option]);
		topMenuOptions.Display(param, TopMenuPosition_LastCategory);
	}
}
