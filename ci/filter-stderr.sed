# Cf. https://github.com/Microsoft/azure-pipelines-tasks/blob/master/docs/authoring/commands.md
/:.*[0-9]: warning:/ {
  s,^\([a-zA-Z]:\)?/.*/build/source/,,
  s,^\([a-zA-Z]:\)?/.*/build/,,
  s,^,##vso[task.LogIssue type=warning;],
  s,^\([^;]*\);\]\([^:]*\):\([0-9]*\):\([0-9]*\): *[Ww]arning: *,\1;sourcepath=\2;linenumber=\3;columnnumber=\4;],
}
/:.*[0-9]: error:/ {
  s,^\([a-zA-Z]:\)?/.*/build/source/,,
  s,^\([a-zA-Z]:\)?/.*/build/,,
  s,^,##vso[task.LogIssue type=error;],
  s,^\([^;]*\);\]\([^:]*\):\([0-9]*\):\([0-9]*\): *[Ee]rror: *,\1;sourcepath=\2;linenumber=\3;columnnumber=\4;],
}
/^CMake Warning at / {
  s,^,##vso[task.LogIssue type=warning;],
  s,^CMake Warning at \([^;]*\);\]\([^:]*\):\([0-9]*\)\(.*\): *[Ww]arning: *,\1;sourcepath=\2;linenumber=\3;]CMake Warning\4,
}
