+++
title = "代码片段 For VSCode"
author = ["Jerling"]
description = "用在 VSCode 上"
date = 2020-04-21
lastmod = 2020-04-21
tags = ["snippets", "VSCode"]
categories = ["效率工具"]
type = "post"
draft = false
author_homepage = "https://github.com/Jerling"
toc = "true"
+++

## 写作目的
每次新换一个环境，就需要重新整理 snippets, 干脆直接记录在博客上。

## markdown

### 插入标题
```json
"head 1": {
    "prefix": "h1",
    "body": "# $1\n"
},
"head 2": {
    "prefix": "h2",
    "body": "## $1\n"
},
"head 3": {
    "prefix": "h3",
    "body": "### $1\n"
},
"head 4": {
    "prefix": "h4",
    "body": "#### $1\n"
},
"head 5": {
    "prefix": "h5",
    "body": "##### $1\n"
},
```

### 插入代码
```json
"code bock": {
    "prefix": "code_block",
    "body": "```$1\n$2\n```\n$3"
},
"code line": {
    "prefix": "code_line",
    "body": "`$1` $2"
}
```

### 日期和时间
```json
"insert date": {
    "prefix": "date",
    "body": "$CURRENT_YEAR-$CURRENT_MONTH-$CURRENT_DATE"
},
"insert time": {
    "prefix": "time",
    "body": "$CURRENT_HOUR:$CURRENT_MINUTE:$CURRENT_SECOND"
}
```

### hugo相关
```json	
"Hugo head": {
		"prefix": "hugo_head",
		"body": [
			"+++",
			"title = \"$1\"",
			"author = [\"Jerling\"]",
			"description = \"$2\"",
			"date = $CURRENT_YEAR-$CURRENT_MONTH-${CURRENT_DATE}T$CURRENT_HOUR:$CURRENT_MINUTE:$CURRENT_SECOND+08:00",
			"lastmod = $CURRENT_YEAR-$CURRENT_MONTH-${CURRENT_DATE}T$CURRENT_HOUR:$CURRENT_MINUTE:$CURRENT_SECOND+08:00",
			"tags = [\"$4\", \"$5\", \"$6\"]",
			"categories = [\"$7\"]",
			"type = \"post\"",
			"draft = false",
			"author_homepage = \"https://github.com/Jerling\"",
			"toc = \"true\"",
			"+++\n\n# $8"
		]
	},
```

```json
"insert figure src": {
    "prefix": "hugo_figure",
    "body": "\{\{< figure src=\"/images/$1.png\" >}}\n"
},
```