#define LOB_CRA_CATEGORY "LoB - Record Announcement"
#define LOB_CRA_VOLUME_STEPS 11 // 0% to 100%
enum RecordAnnounceOption:
{
	RECORDANNOUNCEOPTION_INVALID = -1, 
	RecordAnnounceOption_Type,
	RecordAnnounceOption_Volume,
	RECORDANNOUNCEOPTION_COUNT
};

enum
{
	AnnounceRecordType_None = 0,
	AnnounceRecordType_Local = 1,
	AnnounceRecordType_Global = 2,
	AnnounceRecordType_Both = 3,
	ANNOUNCERECORDTYPE_COUNT
}

stock char gC_CRAOptionNames[RECORDANNOUNCEOPTION_COUNT][] = 
{
	"LOB CRA - Type",
	"LOB CRA - Volume"
};

stock char gC_CRAOptionDescriptions[RECORDANNOUNCEOPTION_COUNT][] = 
{
	"Record Type - 0 = None, 1 = Local Only, 2 = Global Only, 3 = Both",
	"Announcement Volume"
};

stock char gC_CRAOptionPhrases[RECORDANNOUNCEOPTION_COUNT][] = 
{
	"Options Menu - Record Type",
	"Options Menu - Announcement Volume"
};

stock int gI_CRAOptionCounts[RECORDANNOUNCEOPTION_COUNT] = 
{
	ANNOUNCERECORDTYPE_COUNT,
	LOB_CRA_VOLUME_STEPS
};

stock int gI_CRAOptionDefaults[RECORDANNOUNCEOPTION_COUNT] = 
{
	AnnounceRecordType_Both,
	LOB_CRA_VOLUME_STEPS - 1
};

stock char gC_AnnounceRecordTypePhrases[ANNOUNCERECORDTYPE_COUNT][] = 
{
	"Options Menu - None",
	"Options Menu - Local",
	"Options Menu - Global",
	"Options Menu - Both"
};