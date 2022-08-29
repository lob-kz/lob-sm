/*
	SQL query templates.
*/



// =====[ GENERAL ]=====

char sql_players_searchbyalias[] = "\
SELECT SteamID32, Alias \
	FROM Players \
	WHERE Players.Cheater=0 AND LOWER(Alias) LIKE '%%%s%%' \
	ORDER BY (LOWER(Alias)='%s') DESC, LastPlayed DESC \
	LIMIT 1";



// =====[ PROFILE ]=====

char sql_players_profile[] = "\
SELECT Alias, Country, LastPlayed, Created \
	FROM Players \
	WHERE SteamID32=%d";

char sql_getcount_maincoursescompletedoverall[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 \
	AND Times.SteamID32=%d";

char sql_getcount_maincoursescompletedprooverall[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 \
	AND Times.SteamID32=%d AND Times.Teleports=0";

char sql_getcompletedmainmapcoursesoverall[] = "\
SELECT DISTINCT Maps.Name \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool AND Times.SteamID32=%d AND MapCourses.Course=0 \
	ORDER BY Maps.Name";

char sql_getcompletedmainmapcoursesoverall_pro[] = "\
SELECT DISTINCT Maps.Name \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool AND Times.SteamID32=%d AND MapCourses.Course=0 AND Times.Teleports=0 \
	ORDER BY Maps.Name";

char sql_getuncompletedmainmapcoursesoverall[] = "\
SELECT Maps.Name \
	FROM MapCourses \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 AND MapCourses.MapCourseID NOT IN ( \
	SELECT DISTINCT Times.MapCourseID \
	FROM Times \
	WHERE Times.SteamID32=%d) \
	ORDER BY Maps.Name, MapCourses.Course";

char sql_getuncompletedmainmapcoursesoverall_pro[] = "\
SELECT Maps.Name \
	FROM MapCourses \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 AND MapCourses.MapCourseID NOT IN ( \
	SELECT DISTINCT Times.MapCourseID \
	FROM Times \
	WHERE Times.SteamID32=%d AND Times.Teleports=0) \
	ORDER BY Maps.Name, MapCourses.Course";

char sql_getcount_maincourses[] = "\
SELECT COUNT(*) \
	FROM MapCourses \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0";

char sql_players_getalias[] = "\
SELECT Alias \
	FROM Players \
	WHERE SteamID32=%d";



// =====[ MAP COMPLETION ]=====

char sql_getcompletedmainmapcourses[] = "\
SELECT DISTINCT Maps.Name \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool AND Times.SteamID32=%d AND Times.Mode=%d AND MapCourses.Course=0 \
	ORDER BY Maps.Name";

char sql_getcompletedmainmapcourses_pro[] = "\
SELECT DISTINCT Maps.Name \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool AND Times.SteamID32=%d AND Times.Mode=%d AND MapCourses.Course=0 AND Times.Teleports=0 \
	ORDER BY Maps.Name";

char sql_getuncompletedmainmapcourses[] = "\
SELECT Maps.Name \
	FROM MapCourses \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 AND MapCourses.MapCourseID NOT IN ( \
	SELECT DISTINCT Times.MapCourseID \
	FROM Times \
	WHERE Times.SteamID32=%d AND Times.Mode=%d) \
	ORDER BY Maps.Name, MapCourses.Course";

char sql_getuncompletedmainmapcourses_pro[] = "\
SELECT Maps.Name \
	FROM MapCourses \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 AND MapCourses.MapCourseID NOT IN ( \
	SELECT DISTINCT Times.MapCourseID \
	FROM Times \
	WHERE Times.SteamID32=%d AND Times.Mode=%d AND Times.Teleports=0) \
	ORDER BY Maps.Name, MapCourses.Course";
