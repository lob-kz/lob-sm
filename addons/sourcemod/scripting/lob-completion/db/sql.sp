/*
	SQL query templates.
*/



// =====[ QUERIES ]=====

char sql_getcount_maincourses[] = "\
SELECT COUNT(*) \
	FROM MapCourses \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0";

char sql_getcount_maincoursescompletedanymode[] = "\
SELECT COUNT(DISTINCT Times.MapCourseID) \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 \
	AND Times.SteamID32=%d";

char sql_maincoursecompletiontop[] = "\
SELECT Players.Alias, COUNT(DISTINCT Times.MapCourseID) \
	FROM Times \
	INNER JOIN MapCourses ON MapCourses.MapCourseID=Times.MapCourseID \
	INNER JOIN Maps ON Maps.MapID=MapCourses.MapID \
	INNER JOIN Players ON Players.SteamID32=Times.SteamID32 \
	WHERE Maps.InRankedPool=1 AND MapCourses.Course=0 \
	GROUP BY Times.SteamID32 \
	ORDER BY COUNT(DISTINCT Times.MapCourseID) DESC \
	LIMIT %d";
