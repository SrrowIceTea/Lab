/**
 * 面向高中生的「立心之约」人工智能微课——课堂实践模块数据
 *
 * 说明：
 * - 本文件替代原 src/data/ 下的网络安全靶场实验数据（SQL 注入、XSS、CTF 等）。
 * - 模块编号 1-10 与课程目录 PRESENTATION_COURSE_SEEDS 的十讲一一对应。
 * - 所有题目均为 AI 基础知识练习，不依赖 Docker / 靶机 / Flag。
 * - 终端为「教学模拟终端」：命令与输出由本地数据定义，学生输入后写入 TTY 日志，
 *   供 AI 助手读取并给出个性化提示。真实环境接入点见 README「后续替换点」。
 */

export type AiQuestionType = 'single-choice' | 'multiple-choice' | 'short-answer'

export interface AiQuestion {
  id: number
  type: AiQuestionType
  content: string
  score: number
  options?: string[]
  /** 选择题答案（单选为选项下标数组，多选为多个下标）；简答题用 reference 展示参考答案 */
  answer?: number[]
  reference?: string
  analysis?: string
}

export interface AiTaskPoint {
  id: number
  name: string
  description: string
  score: number
  document: string
  questions: AiQuestion[]
}

export interface TerminalCommand {
  description: string
  output: string[]
}

export interface AiModule {
  id: number
  name: string
  introduction: string
  difficulty: number
  category: string
  estimatedTime: string
  objectives: string[]
  taskPoints: AiTaskPoint[]
  terminal: {
    welcome: string[]
    prompt: string
    commands: Record<string, TerminalCommand>
    suggested: string[]
  }
}

const HELP: TerminalCommand = {
  description: '显示可用命令',
  output: [
    '可用命令：help（帮助）、ls（查看文件）、report（查看任务报告）、clear（清屏）',
    '提示：输入 help 后试试课程推荐的命令；你的每条命令和回显都会被 AI 助手读取。'
  ]
}

const REPORT: TerminalCommand = {
  description: '查看当前任务进度',
  output: [
    '[任务面板] 已完成操作记录已同步到本地学习日志。',
    '[任务面板] 接下来可以点击右下角 AI 助手，让它结合日志解释你刚才看到的结果。'
  ]
}

export const AI_MODULES: AiModule[] = [
  {
    id: 1,
    name: 'AI 应用大搜索',
    introduction:
      '从身边的语音助手、刷脸门禁到推荐系统，找出人工智能在生活中的真实应用。通过本讲实践，理解“智能体”与普通程序的根本差别：有没有目标、价值判断与根据环境调整行为的能力。',
    difficulty: 1,
    category: '人工智能基础',
    estimatedTime: '1 小时',
    objectives: [
      '能举出至少 3 个身边的 AI 应用并说明它解决的问题',
      '理解“价值驱动”是智能体与机械运动的分界',
      '初步认识“给机器立心”这句话的含义'
    ],
    taskPoints: [
      {
        id: 101,
        name: '任务一：给身边的 AI 做一次“人口普查”',
        description: '扫描生活中常见的智能产品，记录它们感知什么、决策什么、输出什么。',
        score: 40,
        document: `## 任务背景

同样的运动轨迹，一旦被看成“有意图”，性质就变了。朱松纯教授用一红一绿两个小球说明：红球想出门、绿球去堵门，门口的位置对红球“更有价值”。这就是**价值驱动**。

## 你要做的

1. 在模拟终端输入 \`ls\`，看看今天可以调研的应用场景。
2. 用 \`inspect <应用名>\` 查看它的感知—决策—输出链路。
3. 记录至少 3 个应用，想想它们各自的“价值”是什么。

## 思考

普通计算器与语音助手的区别在哪里？前者只按固定规则算，后者会根据你的目标调整回答。`,
        questions: [
          {
            id: 1001,
            type: 'single-choice',
            content: '下列哪一项最能体现“智能体”与普通程序的根本区别？',
            options: [
              'A. 运算速度更快',
              'B. 有明确目标与价值判断，能根据环境调整行为',
              'C. 使用了高级编程语言',
              'D. 能存储更多数据'
            ],
            score: 10,
            answer: [1],
            analysis: '智能体与普通程序的关键区别是“价值驱动”，即它有想达成的目标，并会随环境变化调整策略。'
          },
          {
            id: 1002,
            type: 'multiple-choice',
            content: '下面哪些属于人工智能的典型应用？（多选）',
            options: ['A. 手机语音助手', 'B. 电商推荐系统', 'C. 自动售货机的按键', 'D. 人脸识别门禁'],
            score: 10,
            answer: [0, 1, 3],
            analysis: '按键只是机械响应；语音助手、推荐系统、人脸识别都涉及感知、判断与决策。'
          },
          {
            id: 1003,
            type: 'short-answer',
            content: '结合一个具体例子，说说你对“给机器立心”的理解。',
            score: 20,
            reference:
              '参考要点：以导航软件为例，它不只是计算路线，还会依据“更快到达”这一目标，结合实时路况不断改道；这里的“心”就是目标与价值函数。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['AI 课堂模拟终端 v1.0', '本终端不连接任何容器。输入 help 查看可用命令。'],
      prompt: 'ai-lab>',
      commands: {
        help: HELP,
        ls: {
          description: '列出可调研的 AI 应用',
          output: ['发现 5 个应用场景：', '  语音助手 / 人脸识别门禁 / 推荐系统 / 自动驾驶 / 智能音箱']
        },
        inspect: {
          description: '查看某个应用的感知—决策—输出链路',
          output: [
            '[语音助手] 感知：麦克风采集声波 → 语音识别',
            '[语音助手] 决策：理解意图，判断用户想做什么',
            '[语音助手] 输出：生成回答或执行动作（播放音乐、设闹钟）',
            '[价值] 目标：尽快、准确地满足用户请求'
          ]
        },
        report: REPORT
      },
      suggested: ['ls', 'inspect 语音助手', 'report']
    }
  },
  {
    id: 2,
    name: '图像识别初体验',
    introduction:
      '机器“看得见”像素，却要“看得懂”意义。本节通过一张图片的识别过程，认识图像采集、特征提取与卷积神经网络，理解人脸识别、自动驾驶感知背后的基本原理。',
    difficulty: 2,
    category: '感知智能',
    estimatedTime: '1-2 小时',
    objectives: [
      '理解图像在计算机中是一组像素数值',
      '了解卷积网络逐层提取特征的基本思路',
      '能解释图像识别出错的可能原因'
    ],
    taskPoints: [
      {
        id: 201,
        name: '任务一：让机器认出一张图',
        description: '在模拟终端完成分类、解释与评估三步，观察机器“看错”的时刻。',
        score: 40,
        document: `## 任务背景

人眼并不是照相机：视野中心只有 5–10 度清晰，还有盲区，却能通过“脑补”把线段和色块看成故事。计算机视觉走的正是从**像素 → 符号 → 意义**的道路。

## 你要做的

1. \`python classify.py --image cat.png\` 查看分类结果。
2. \`python explain.py --layer conv1\` 看看网络第一层学到了什么。
3. \`python eval.py\` 观察模型在困难样本上的表现。`,
        questions: [
          {
            id: 2001,
            type: 'single-choice',
            content: '卷积神经网络在图像识别中的主要作用是：',
            options: [
              'A. 把图片压缩成一个数字',
              'B. 逐层提取从边缘、纹理到物体部件的特征',
              'C. 直接把图片变成文字',
              'D. 增加图片的分辨率'
            ],
            score: 10,
            answer: [1],
            analysis: '卷积网络通过多层卷积逐步提取由低级到高级的特征，这是它理解图像的关键。'
          },
          {
            id: 2002,
            type: 'multiple-choice',
            content: '导致图像识别模型出错的常见原因有哪些？（多选）',
            options: [
              'A. 训练数据中缺少类似场景',
              'B. 图片被遮挡或光照异常',
              'C. 把人眼的“脑补”当成机器的理解',
              'D. 图片文件是 PNG 格式'
            ],
            score: 10,
            answer: [0, 1, 2],
            analysis: '数据覆盖不足、遮挡与光照变化、以及对机器能力的误解，都是常见原因；文件格式本身不是问题。'
          },
          {
            id: 2003,
            type: 'short-answer',
            content: '为什么说“人眼是一套靠脑补运作的建构系统”？',
            score: 20,
            reference:
              '参考要点：人眼只有中心小范围清晰、存在盲区，还会漏看画面中的显著变化；但我们主观上看到的是完整、有意义的场景，说明视觉是大脑主动建构的结果。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['视觉实验室模拟终端', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'vision>',
      commands: {
        help: HELP,
        ls: {
          description: '列出可用图片',
          output: ['images/', '  cat.png   dog.png   stop_sign.png   blurry_cat.png']
        },
        classify: {
          description: '运行图像分类',
          output: [
            '[classify] 加载模型 resnet-sim ...',
            '[classify] cat.png → 猫 0.91 / 狐狸 0.06 / 其他 0.03',
            '[classify] blurry_cat.png → 猫 0.42 / 狐狸 0.38 / 其他 0.20',
            '[提示] 模糊样本上模型开始犹豫，这正是识别的难点。'
          ]
        },
        explain: {
          description: '查看网络学到的特征',
          output: [
            '[conv1] 第 1 层：边缘、颜色纹理',
            '[conv2] 第 2 层：眼睛、耳朵等局部形状',
            '[conv3] 第 3 层：猫脸、车身等部件组合'
          ]
        },
        eval: {
          description: '查看评估结果',
          output: ['[eval] 清晰样本准确率 92%', '[eval] 模糊/遮挡样本准确率 61%', '[建议] 需要更多困难样本参与训练。']
        },
        report: REPORT
      },
      suggested: ['ls', 'python classify.py --image cat.png', 'python explain.py --layer conv1', 'eval']
    }
  },
  {
    id: 3,
    name: '让机器给句子分类',
    introduction:
      '从分词、词向量到大语言模型，理解机器如何理解与生成人类语言。重点体会自然语言的两大难点：歧义，以及说话人没写出来的“言外之意”。',
    difficulty: 2,
    category: '感知智能',
    estimatedTime: '1-2 小时',
    objectives: [
      '理解分词需要结合语义才能做对',
      '了解词向量把词语放到高维空间的思想',
      '能识别语用含义（如婉拒）'
    ],
    taskPoints: [
      {
        id: 301,
        name: '任务一：分词、词向量与言外之意',
        description: '用模拟命令观察一句话如何被机器拆解、表示和理解。',
        score: 40,
        document: `## 任务背景

“一行行行行，一行不行行行不行”——同一个“行”字读音不同、意思全变。还有“无线电台 / 法国 / 别研究”这样的分词陷阱：只按词频切分，会得到荒谬的结果。

## 你要做的

1. \`nlp tokenize "无线电台法国别研究"\` 观察分词结果。
2. \`nlp embed 国王 男人 女人\` 看看词向量的“运算”。
3. \`nlp pragmatics "晚上看电影吗？我明天有考试。"\` 理解言外之意。`,
        questions: [
          {
            id: 3001,
            type: 'single-choice',
            content: '“无线电台法国别研究”正确的分词结果是：',
            options: [
              'A. 无线 / 电法 / 国别 / 研究',
              'B. 无线电 / 法国 / 别研究',
              'C. 无线电台 / 法国 / 别研究',
              'D. 无线电台法国 / 别 / 研究'
            ],
            score: 10,
            answer: [2],
            analysis: '只有结合语义理解，才知道这里说的是“无线电台”“法国”和“别研究”。'
          },
          {
            id: 3002,
            type: 'single-choice',
            content: '词向量模型中，“国王 - 男人 + 女人 ≈ 女王”说明了什么？',
            options: [
              'A. 词在空间中位置随机',
              'B. 语义关系可以用向量运算表示',
              'C. 计算机能真正理解国王的含义',
              'D. 词向量只能表示字数'
            ],
            score: 10,
            answer: [1],
            analysis: '词向量把语义相近的词放在相近位置，某些语义关系呈现近似平行的向量关系。'
          },
          {
            id: 3003,
            type: 'short-answer',
            content: '别人问“晚上看电影吗”，你回答“我明天有考试”。从语用角度看，这句话是什么意思？',
            score: 20,
            reference:
              '参考要点：这是间接的婉拒。虽然字面上没有说“不去”，但“明天有考试”暗示要复习、没时间，听者可以推断出拒绝的意图。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['自然语言处理模拟终端', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'nlp>',
      commands: {
        help: HELP,
        tokenize: {
          description: '对句子分词',
          output: [
            '[tokenize] 输入：无线电台法国别研究',
            '[tokenize] 按频率切分：无线电 / 法国别 / 研究  ← 语义不通',
            '[tokenize] 结合语义：无线电台 / 法国 / 别研究  ← 正确',
            '[结论] 分词必须与语义理解交互进行。'
          ]
        },
        embed: {
          description: '演示词向量关系',
          output: [
            '[embed] 国王 → [0.82, 0.31, 0.47]',
            '[embed] 男人 → [0.79, -0.12, 0.41]',
            '[embed] 女人 → [0.31, -0.15, 0.68]',
            '[embed] 国王 - 男人 + 女人 ≈ 女王：语义关系可被向量运算捕捉'
          ]
        },
        pragmatics: {
          description: '分析言外之意',
          output: [
            '[语用分析] 字面含义：明天有考试',
            '[语用分析] 隐含意图：晚上要看书，无法赴约',
            '[语用分析] 结论：这是一次委婉的拒绝'
          ]
        },
        report: REPORT
      },
      suggested: ['nlp tokenize "无线电台法国别研究"', 'nlp embed 国王 男人 女人', 'report']
    }
  },
  {
    id: 4,
    name: '搭一个知识图谱',
    introduction:
      '从感知到认知，中间差的是推理。本节用校园场景搭建小型知识图谱，认识实体、关系与规则，理解机器怎样基于物理属性和因果关系做判断。',
    difficulty: 3,
    category: '认知与决策',
    estimatedTime: '1-2 小时',
    objectives: [
      '理解知识图谱的三元组表示',
      '了解基于属性的常识推理',
      '认识婴儿实验对人工智能的启发'
    ],
    taskPoints: [
      {
        id: 401,
        name: '任务一：为校园建一个小型知识图谱',
        description: '添加实体与关系，用简单规则推导新知识。',
        score: 40,
        document: `## 任务背景

判断一块石头能不能砸核桃，靠的不是它叫“石头”，而是它的**物理属性**：够硬、有一定重量。这种常识推理，连 6 个月的婴儿都已经具备，却是今天 AI 的短板。

## 你要做的

1. \`kg add 小明 朋友 小华\` 添加一条关系。
2. \`kg query 小明的朋友\` 查询。
3. \`kg infer 小明 北京大学 踢足球\` 看看系统如何补出“事件”结构。`,
        questions: [
          {
            id: 4001,
            type: 'single-choice',
            content: '判断“这块石头能不能砸开核桃”，机器主要需要依赖：',
            options: ['A. 石头的名字', 'B. 石头的物理属性与因果知识', 'C. 石头的照片颜色', 'D. 石头在词典中的页码'],
            score: 10,
            answer: [1],
            analysis: '认知推理依赖物体的属性与因果结构，而不是标签本身。'
          },
          {
            id: 4002,
            type: 'multiple-choice',
            content: '一个知识图谱的三元组可以包含哪些部分？（多选）',
            options: ['A. 实体', 'B. 关系', 'C. 属性值', 'D. 随机噪声'],
            score: 10,
            answer: [0, 1, 2],
            analysis: '知识图谱以实体—关系—实体或实体—属性—值的三元组组织知识。'
          },
          {
            id: 4003,
            type: 'short-answer',
            content: '发展心理学中的“违反预期法”为什么能研究婴儿懂不懂物理常识？',
            score: 20,
            reference:
              '参考要点：婴儿不会说话，但当看到的事件违反物理规律（如物体穿墙）时，会表现出更长的注视时间；注视时长差异说明婴儿对规律已有预期。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['认知推理模拟终端', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'kg>',
      commands: {
        help: HELP,
        add: {
          description: '添加三元组',
          output: ['[kg] 已添加：(小明, 朋友, 小华)', '[kg] 已添加：(小明, 地点, 北京大学)']
        },
        query: {
          description: '查询关系',
          output: ['[kg] 小明的朋友 → 小华', '[kg] 小明所在地点 → 北京大学']
        },
        infer: {
          description: '基于依存关系推理事件',
          output: [
            '[依存分析] 事件：踢足球',
            '  施事：小明',
            '  受事：足球',
            '  处所：北京大学',
            '  并列：小华',
            '[结论] 小明和小华在北京大学踢足球'
          ]
        },
        report: REPORT
      },
      suggested: ['kg add 小明 朋友 小华', 'kg query 小明的朋友', 'kg infer 小明 北京大学 踢足球']
    }
  },
  {
    id: 5,
    name: '训练第一个分类器',
    introduction:
      '机器能不能靠经验自己长大？本节用可视化的数据集，体验监督学习的完整流程：训练、评估、调参，并理解统计学习、功能学习、价值学习三个层级。',
    difficulty: 3,
    category: '认知与决策',
    estimatedTime: '1-2 小时',
    objectives: [
      '理解监督学习“从样例中归纳规律”的过程',
      '知道过拟合的表现与应对方法',
      '区分统计学习、功能学习与价值学习'
    ],
    taskPoints: [
      {
        id: 501,
        name: '任务一：让模型学会分类',
        description: '在终端完成训练、评估和调参三轮实验。',
        score: 40,
        document: `## 任务背景

学习的本质可以理解为“具有语义信息的高效传输与通讯”。机器学习分三层：**统计学习**（认形状）、**功能学习**（认用途）、**价值学习**（认价值）。

## 你要做的

1. \`ml train --data iris.csv\` 训练第一个分类器。
2. \`ml evaluate\` 查看准确率与混淆情况。
3. \`ml tune --epochs 5 --noise 0.2\` 观察过拟合：训练集变好，测试集变差。`,
        questions: [
          {
            id: 5001,
            type: 'single-choice',
            content: '监督学习训练时需要提供什么？',
            options: ['A. 只有输入数据', 'B. 输入数据及其对应的正确答案（标签）', 'C. 只提供规则', 'D. 只提供算力'],
            score: 10,
            answer: [1],
            analysis: '监督学习从“输入—标签”成对样本中学习映射关系。'
          },
          {
            id: 5002,
            type: 'single-choice',
            content: '过拟合的典型表现是：',
            options: [
              'A. 训练集和测试集准确率都很低',
              'B. 训练集准确率高，测试集准确率明显下降',
              'C. 模型完全无法运行',
              'D. 数据量自动变多'
            ],
            score: 10,
            answer: [1],
            analysis: '过拟合是模型记住了训练样本的细节和噪声，泛化到新数据时表现变差。'
          },
          {
            id: 5003,
            type: 'short-answer',
            content: '“乌鸦范式”和“鹦鹉范式”分别指什么？为什么通用智能更看重前者？',
            score: 20,
            reference:
              '参考要点：鹦鹉范式是大数据单任务、靠重复训练取得高分；乌鸦范式是小数据多任务、靠理解与迁移解决问题。通用智能需要在新情境中举一反三，因此更看重乌鸦范式。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['机器学习模拟终端', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'ml>',
      commands: {
        help: HELP,
        train: {
          description: '训练分类器',
          output: [
            '[train] 载入 iris.csv：150 条样本 / 3 类',
            '[train] epoch 1/10  loss=0.84  acc=0.61',
            '[train] epoch 10/10 loss=0.21  acc=0.94',
            '[train] 训练完成。试试 ml evaluate。'
          ]
        },
        evaluate: {
          description: '在测试集上评估',
          output: ['[eval] 测试集准确率：0.91', '[eval] 混淆： versicolor 被误判为 virginica 3 次', '[提示] 混淆来自特征相似。']
        },
        tune: {
          description: '调参并观察过拟合',
          output: [
            '[tune] epochs=200, noise=0.2',
            '[tune] 训练集准确率：0.99',
            '[tune] 测试集准确率：0.84  ← 下降',
            '[结论] 训练太久会把噪声也记下来，这就是过拟合。'
          ]
        },
        report: REPORT
      },
      suggested: ['ml train --data iris.csv', 'ml evaluate', 'ml tune --epochs 200 --noise 0.2']
    }
  },
  {
    id: 6,
    name: '设计一台服务机器人',
    introduction:
      '机器人走进生活，需要“场景理解”和“任务执行”两大能力。本节围绕校园导览场景，画出感知—决策—执行闭环，理解为什么机器人“原理简单、实现困难”。',
    difficulty: 2,
    category: '具身智能',
    estimatedTime: '1-2 小时',
    objectives: [
      '描述机器人的感知—决策—执行闭环',
      '了解定位与路径规划中的现实困难',
      '能解释“原理简单、实现困难”'
    ],
    taskPoints: [
      {
        id: 601,
        name: '任务一：给机器人做一次校园导览规划',
        description: '扫描环境、定位、规划路径并执行动作。',
        score: 40,
        document: `## 任务背景

三角定位的原理很简单，但真实机器人会遇到相对论修正、视觉遮挡、误差累积、逆运动学多解等问题。这正是本讲的底色：**原理简单、实现困难**。

## 你要做的

1. \`robot scan\` 扫描校园环境。
2. \`robot locate\` 查看定位结果和误差来源。
3. \`robot plan --goal 校门口\` 生成路径，再用 \`robot move\` 执行。`,
        questions: [
          {
            id: 6001,
            type: 'single-choice',
            content: '机器人完成“把水杯递给我”的任务，正确的能力顺序是：',
            options: [
              'A. 执行 → 感知 → 决策',
              'B. 感知 → 决策 → 执行',
              'C. 决策 → 执行 → 感知',
              'D. 只需要执行'
            ],
            score: 10,
            answer: [1],
            analysis: '机器人先感知环境，再决策规划，最后执行动作，构成闭环。'
          },
          {
            id: 6002,
            type: 'multiple-choice',
            content: '哪些因素会让真实机器人定位变困难？（多选）',
            options: ['A. 传感器误差累积', 'B. 视觉遮挡', 'C. 环境动态变化', 'D. 机器人有轮子'],
            score: 10,
            answer: [0, 1, 2],
            analysis: '误差累积、遮挡和动态环境都是定位的难点；轮子本身不是问题。'
          },
          {
            id: 6003,
            type: 'short-answer',
            content: '为什么说机器人“原理简单、实现困难”？举一个课堂上的例子。',
            score: 20,
            reference:
              '参考要点：例如逆运动学， textbook 上列方程求角度即可，但真实机械臂会遇到多解、奇异位形（除零）、关节限位等问题，需要滤波、标定和冗余设计。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['机器人仿真终端（无容器依赖）', '输入 help 查看命令。'],
      prompt: 'robot>',
      commands: {
        help: HELP,
        scan: {
          description: '扫描环境',
          output: [
            '[scan] 检测到 12 个视觉特征点',
            '[scan] 障碍物：长廊立柱 ×2、台阶 ×1',
            '[scan] 目标区域：校门口（东北方向 48 m）'
          ]
        },
        locate: {
          description: '查看定位结果',
          output: [
            '[locate] 三角定位估计：(12.3, 7.8)',
            '[locate] 置信度 0.86；误差来源：特征点遮挡 2 个、轮子打滑累计 0.4 m'
          ]
        },
        plan: {
          description: '规划路径',
          output: ['[plan] 生成路径：当前位置 → 走廊 → 大厅 → 校门口', '[plan] 预计 52 秒，避开台阶与立柱']
        },
        move: {
          description: '执行动作',
          output: ['[move] 已移动 48 m，到达校门口', '[move] 实际偏差 0.6 m，位置细胞修正完成']
        },
        report: REPORT
      },
      suggested: ['robot scan', 'robot locate', 'robot plan --goal 校门口', 'robot move']
    }
  },
  {
    id: 7,
    name: '多智能体协作推演',
    introduction:
      '当世界上不止一个聪明个体，智能会变成什么样？本节从蜂群、蚁群讲到游戏 AI 与博弈论，理解“人类智能本质上是社会性智能”。',
    difficulty: 4,
    category: '具身智能',
    estimatedTime: '2 小时',
    objectives: [
      '理解群体智能不需要“总指挥”',
      '了解囚徒困境揭示的个人理性与集体困境',
      '初步认识心智理论（替别人想）'
    ],
    taskPoints: [
      {
        id: 701,
        name: '任务一：让三个智能体学会合作',
        description: '生成智能体、设置策略、运行多轮博弈并解读统计结果。',
        score: 40,
        document: `## 任务背景

蜂群和蚁群没有总指挥，却能把搬食物、筑巢做得井井有条。在人这里，合作需要“心智理论”——推测别人心里怎么想。囚徒困境则告诉我们：人人选对自己最优，结果可能对集体最差。

## 你要做的

1. \`sim spawn --agents 3\` 生成三个智能体。
2. \`sim set strategy tit-for-tat\` 设置“以牙还牙”策略。
3. \`sim run --rounds 10\` 运行十轮，看看总分。`,
        questions: [
          {
            id: 7001,
            type: 'single-choice',
            content: '“囚徒困境”主要说明了什么？',
            options: [
              'A. 人工智能一定比人聪明',
              'B. 个人理性选择可能导致集体较差的结果',
              'C. 合作永远不可能出现',
              'D. 博弈论只适用于棋盘游戏'
            ],
            score: 10,
            answer: [1],
            analysis: '囚徒困境揭示了个体最优与集体最优之间的冲突；重复博弈中合作策略（如以牙还牙）可以涌现。'
          },
          {
            id: 7002,
            type: 'multiple-choice',
            content: '哪些现象体现了群体智能？（多选）',
            options: ['A. 蚁群找到最短觅食路径', 'B. 蜂群调节巢内温度', 'C. 单个人下棋', 'D. 无人机编队保持队形'],
            score: 10,
            answer: [0, 1, 3],
            analysis: '群体智能强调个体间简单规则交互产生整体有序行为，单人下棋不属于此列。'
          },
          {
            id: 7003,
            type: 'short-answer',
            content: '“心智理论”对人机协作为什么重要？',
            score: 20,
            reference:
              '参考要点：机器若能推测人的信念、意图和知识状态，就能解释“我明天有考试”这类话、理解“泥巴孩子”谜题，从而做出合乎情境的合作行为。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['多智能体仿真终端（本地模拟）', '输入 help 查看命令；不连接任何容器。'],
      prompt: 'sim>',
      commands: {
        help: HELP,
        spawn: {
          description: '生成智能体',
          output: ['[sim] 已生成 3 个智能体：A1 / A2 / A3', '[sim] 初始策略：随机']
        },
        strategy: {
          description: '设置博弈策略',
          output: ['[sim] 策略已设为 tit-for-tat：首轮合作，之后复制对方上一轮选择']
        },
        run: {
          description: '运行多轮博弈',
          output: [
            '[sim] 轮次 1-3：三方合作，各得 3 分',
            '[sim] 轮次 4：A2 背叛，A2 得 5 分，A1/A3 各得 0 分',
            '[sim] 轮次 5-10：A1/A3 转而背叛，平均收益下降',
            '[结论] 一次背叛短期有利，长期会破坏合作'
          ]
        },
        report: REPORT
      },
      suggested: ['sim spawn --agents 3', 'sim set strategy tit-for-tat', 'sim run --rounds 10']
    }
  },
  {
    id: 8,
    name: '搭建简易物理仿真',
    introduction:
      '机器人不能靠在真实世界里不断摔打来学习。本节认识数字孪生与物理引擎，理解 AI 如何在仿真世界里高速试错，再把经验迁移回现实。',
    difficulty: 4,
    category: '具身智能',
    estimatedTime: '2 小时',
    objectives: [
      '理解仿真环境对 AI 训练的价值',
      '了解几何、物理动态与运动控制三层仿真',
      '能说出仿真到现实的差距'
    ],
    taskPoints: [
      {
        id: 801,
        name: '任务一：在仿真世界里做一次自由落体实验',
        description: '创建世界、投放物体、推进时间并观察数据。',
        score: 40,
        document: `## 任务背景

陈宝权教授讲过：用图形学造一个在几何、物理、运动控制上都和现实对应的“数字孪生世界”，机器就能在里面高速试错，而不必担心摔坏。

## 你要做的

1. \`world create --gravity 9.8\` 建立仿真世界。
2. \`world drop --object ball --height 2\` 投放一个小球。
3. \`world step --frames 100\` 推进 100 帧，看位移和速度。`,
        questions: [
          {
            id: 8001,
            type: 'single-choice',
            content: 'AI 训练大量使用仿真环境，最主要的原因是：',
            options: [
              'A. 仿真里的画面更好看',
              'B. 可以低成本、安全、高速地试错',
              'C. 仿真不需要写程序',
              'D. 现实世界没有物理规律'
            ],
            score: 10,
            answer: [1],
            analysis: '仿真的核心价值是让智能体在安全、可控、可加速的环境中积累大量试错经验。'
          },
          {
            id: 8002,
            type: 'multiple-choice',
            content: '一个可信的物理仿真世界需要包含哪些层次？（多选）',
            options: ['A. 几何与外观', 'B. 物理动态（碰撞、重力）', 'C. 运动控制', 'D. 随机的背景音乐'],
            score: 10,
            answer: [0, 1, 2],
            analysis: '几何、物理动态与运动控制是构建可信仿真世界的三层基础。'
          },
          {
            id: 8003,
            type: 'short-answer',
            content: '为什么说把仿真经验迁移到现实世界并不容易？',
            score: 20,
            reference:
              '参考要点：真实世界存在摩擦力变化、传感器噪声、材质差异等仿真难以完全复现的细节，存在“现实差距”；需要使用域随机化、虚实融合等方法缩小差距。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['物理仿真终端（教学模拟）', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'world>',
      commands: {
        help: HELP,
        create: {
          description: '建立仿真世界',
          output: ['[world] 已创建仿真场景：gravity=9.8 m/s²，time_step=1/60 s', '[world] 渲染模式：几何 + 物理动态 + 运动控制']
        },
        drop: {
          description: '投放物体',
          output: ['[world] ball 已从 2.0 m 高度释放', '[world] 预计落地时间约 0.64 s']
        },
        step: {
          description: '推进仿真时间',
          output: [
            '[step] frame 1-30：下落 1.23 m，速度 7.84 m/s',
            '[step] frame 38：接触地面，反弹速度 -5.2 m/s（弹性系数 0.66）',
            '[step] frame 100：能量衰减，小球趋于静止'
          ]
        },
        report: REPORT
      },
      suggested: ['world create --gravity 9.8', 'world drop --object ball --height 2', 'world step --frames 100']
    }
  },
  {
    id: 9,
    name: '生成一段 AI 旋律',
    introduction:
      '音乐这么抽象、这么依赖灵感，机器能不能插手？本节以 AI 续写贝多芬《第十交响曲》为引子，认识音乐特征、旋律生成与风格迁移，讨论人工智能在艺术创作中的可能性与边界。',
    difficulty: 2,
    category: '智能创作',
    estimatedTime: '1 小时',
    objectives: [
      '了解音乐为什么对深度学习特别困难',
      '知道乐谱 → MIDI → 音频的技术链路',
      '能表达自己对 AI 音乐创作的看法'
    ],
    taskPoints: [
      {
        id: 901,
        name: '任务一：让机器写 8 小节旋律',
        description: '分析主题、设定风格、生成旋律并试听。',
        score: 40,
        document: `## 任务背景

音乐数据“小、抽象、难解释”：它没有图像那样海量的标注数据，好不好听也很难写成公式。AI 续写贝多芬第十交响曲时，网上评价两极——有人说是“用数学公式复制”，有人说“真有贝多芬的感觉”。

## 你要做的

1. \`music analyze --file theme.mid\` 分析一段主题旋律。
2. \`music generate --style classical --bars 8\` 生成 8 小节。
3. \`music play\` 试听，写下你的判断。`,
        questions: [
          {
            id: 9001,
            type: 'single-choice',
            content: 'MIDI 文件在音乐生成系统中主要表示什么？',
            options: [
              'A. 人声录音的压缩音频',
              'B. 音符、时值、力度等符号化演奏信息',
              'C. 音乐厅的建筑图纸',
              'D. 歌词的文字文件'
            ],
            score: 10,
            answer: [1],
            analysis: 'MIDI 记录的是符号化的演奏指令（音高、时值、力度等），便于模型处理与编辑。'
          },
          {
            id: 9002,
            type: 'multiple-choice',
            content: '音乐对深度学习不友好的原因有哪些？（多选）',
            options: [
              'A. 高质量标注数据相对稀少',
              'B. 好坏评价高度主观、难以形式化',
              'C. 音乐完全没有结构',
              'D. 风格与情感依赖上下文'
            ],
            score: 10,
            answer: [0, 1, 3],
            analysis: '音乐有结构，但数据稀缺、评价主观、上下文依赖强，这些才是难点。'
          },
          {
            id: 9003,
            type: 'short-answer',
            content: '你怎么看“AI 续写贝多芬第十交响曲”？说说理由。',
            score: 20,
            reference:
              '参考要点：开放题。可从“技术是否真正理解音乐”“作品是否有审美价值”“是否应标注 AI 参与”等角度讨论，言之成理即可。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['音乐生成模拟终端', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'music>',
      commands: {
        help: HELP,
        analyze: {
          description: '分析旋律特征',
          output: [
            '[analyze] 调性：C 大调；拍号：4/4；速度：120 BPM',
            '[analyze] 音域：C4-G5；主要动机：上行三度 + 级进下行',
            '[analyze] 和声进行：I - V - vi - IV'
          ]
        },
        generate: {
          description: '生成指定风格与长度',
          output: [
            '[generate] 载入风格模型：classical-sim',
            '[generate] 已生成 8 小节，共 37 个音符',
            '[generate] 动机保持度 0.78，和声合理性 0.85',
            '[提示] 试试 music play 试听。'
          ]
        },
        play: {
          description: '试听生成结果',
          output: ['[play] ▶ 播放第 1-8 小节 ...', '[play] 旋律听感完整，但第 6 小节转调略显生硬。']
        },
        report: REPORT
      },
      suggested: ['music analyze --file theme.mid', 'music generate --style classical --bars 8', 'music play']
    }
  },
  {
    id: 10,
    name: '我的 AI 学习计划',
    introduction:
      '作为全课收官，本节把十讲串联起来：智能已成为独立一级学科，北大 2002 年设立全球首个智能科学系。任务是结合自己的兴趣，制定一份面向高中生的 AI 学习路线图。',
    difficulty: 1,
    category: '人工智能基础',
    estimatedTime: '1 小时',
    objectives: [
      '回顾十讲的知识地图',
      '了解 AI 作为学科的基本建制',
      '制定一份可执行的学习计划'
    ],
    taskPoints: [
      {
        id: 1001,
        name: '任务一：制定我的 AI 学习路线图',
        description: '回看十讲，选择方向，生成并检查自己的学习计划。',
        score: 40,
        document: `## 任务背景

十讲不是十个孤立专题，而是一张地图：第 1 讲讲“给机器立心”，第 2–7 讲分别讲视觉、语言、认知、学习、运动、社会六大领域，第 8–9 讲是仿真与音乐两个纵深样本，第 10 讲回到学科与人的选择。

## 你要做的

1. \`plan list\` 查看十讲知识地图。
2. \`plan set --focus 方向\` 设定你的兴趣方向。
3. \`plan check\` 检查计划是否具体、可执行。`,
        questions: [
          {
            id: 10001,
            type: 'single-choice',
            content: '我国在哪一年将“智能”增列为一级学科？',
            options: ['A. 2002 年', 'B. 2012 年', 'C. 2022 年', 'D. 2025 年'],
            score: 10,
            answer: [2],
            analysis: '2022 年，智能成为独立的一级学科；北大在 2002 年设立了全球首个智能科学系。'
          },
          {
            id: 10002,
            type: 'multiple-choice',
            content: '朱松纯教授概括的智能六大核心领域包括哪些？（多选）',
            options: ['A. 视觉与语言', 'B. 认知与学习', 'C. 运动与社会', 'D. 天文学'],
            score: 10,
            answer: [0, 1, 2],
            analysis: '六大领域是视觉、语言、认知、运动、学习、社会。'
          },
          {
            id: 10003,
            type: 'short-answer',
            content: '写一条属于你自己的、可执行的 AI 学习计划（至少包含目标、行动和检验方式）。',
            score: 20,
            reference:
              '参考示例：目标——理解图像识别的基本原理；行动——两周内完成第 2 讲与“图像识别初体验”实践，并用手机拍 10 张图记录识别结果；检验——能向同学解释模型为什么会认错，并写出 3 条原因。'
          }
        ]
      }
    ],
    terminal: {
      welcome: ['学习计划终端', '输入 help 查看命令；本终端不连接任何容器。'],
      prompt: 'plan>',
      commands: {
        help: HELP,
        list: {
          description: '列出十讲知识地图',
          output: [
            '01 现状趋势与战略（总纲）   02 计算机视觉   03 自然语言处理',
            '04 认知推理                 05 机器学习     06 智能机器人',
            '07 多智能体                 08 物理仿真     09 人工智能音乐',
            '10 人工智能在北大（学科与培养）'
          ]
        },
        set: {
          description: '设定学习方向',
          output: ['[plan] 已记录你的兴趣方向。', '[plan] 建议：先回看对应讲次，再完成同名课堂实践。']
        },
        check: {
          description: '检查计划完整性',
          output: ['[check] 计划要素：目标 ✓  行动 ✓  检验方式 ✓', '[check] 建议把“检验方式”写得更具体，例如“用 3 张图片测试并记录准确率”。']
        },
        report: REPORT
      },
      suggested: ['plan list', 'plan set --focus 计算机视觉', 'plan check']
    }
  }
]

/** 按模块 ID 查找 AI 实践模块 */
export function findAiModuleById(id: number | string): AiModule | undefined {
  const numericId = Number(id)
  return AI_MODULES.find((m) => m.id === numericId)
}

/** 获取终端命令的标准输出（未知命令给出友好提示） */
export function getTerminalOutput(module: AiModule, rawCommand: string): string[] {
  const trimmed = rawCommand.trim()
  if (!trimmed) return []
  const key = trimmed.split(/\s+/)[0].toLowerCase()
  const command = module.terminal.commands[key]
  if (command) return command.output
  if (key === 'clear') return ['__CLEAR__']
  return [
    `未知命令：${trimmed}`,
    `本模块支持的命令：${Object.keys(module.terminal.commands).join('、')}、clear`
  ]
}
