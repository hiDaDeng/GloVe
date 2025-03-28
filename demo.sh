#!/bin/bash
set -e
make


#设置语料数据文件
#注意: 中文语料文件必须是分词后的文本文件。
#如 「我是中国人，我爱中国」 要整备成 「我 是 中国人 ， 我 爱 中国」
CORPUS_FILE=三体.txt

# 创建 output 文件夹，保存训练结果(模型文件bin/txt等文件)
OUTPUT_DIR="output"
mkdir -p "$OUTPUT_DIR"
CORPUS_NAME="${CORPUS_FILE%.*}" # 去除文件扩展名
VOCAB_FILE="${OUTPUT_DIR}/${CORPUS_NAME}_vocab.txt"
COOCCURRENCE_FILE="${OUTPUT_DIR}/${CORPUS_NAME}_cooccurrence.bin"
COOCCURRENCE_SHUF_FILE="${OUTPUT_DIR}/${CORPUS_NAME}_cooccurrence.shuf.bin"
BUILDDIR=build
SAVE_FILE="${OUTPUT_DIR}/${CORPUS_NAME}_vectors"

# 控制程序输出详细程度的参数
# 值为 0 时输出最少信息，值越大输出信息越详细
VERBOSE=2

# 程序运行时允许使用的最大内存，单位为 GB
# 注意: 此值越大，程序运行速度可能越快，但也会占用更多系统资源
MEMORY=4.0

# 词汇表中单词的最小出现次数
# 出现次数低于此值的单词将被忽略，以减少词汇表的大小
# 注意: 此值越大，模型可能越精确，但词汇表也会越小
VOCAB_MIN_COUNT=5

# 每个单词向量的维度大小
# 维度越大，向量表示的信息越丰富，但计算成本也越高
VECTOR_SIZE=50   #向量维数(维度数)

# 训练模型的最大迭代次数
# 迭代次数越多，模型可能越精确，但训练时间也会相应增加
MAX_ITER=15

# 计算共现矩阵时考虑的上下文窗口大小
# 即当前单词前后各多少个单词会被考虑在内
WINDOW_SIZE=15   

# 训练模型时使用的线程数量
# 线程数越多，训练速度可能越快，但也会占用更多系统资源
NUM_THREADS=8

#共现矩阵中元素的最大计数值； 超过此值的元素将被截断为该值
X_MAX=10  

BINARY=2

if hash python 2>/dev/null; then
    PYTHON=python
else
    PYTHON=python3
fi

# 检查 build 目录和 vocab_count 文件是否存在
if [ ! -d "$BUILDDIR" ]; then
    echo "Error: $BUILDDIR directory does not exist."
    exit 1
fi

if [ ! -x "$BUILDDIR/vocab_count" ]; then
    echo "Error: $BUILDDIR/vocab_count executable does not exist or is not executable."
    exit 1
fi

echo
echo "$ $BUILDDIR/vocab_count -min-count $VOCAB_MIN_COUNT -verbose $VERBOSE < $CORPUS_FILE > $VOCAB_FILE"
$BUILDDIR/vocab_count -min-count $VOCAB_MIN_COUNT -verbose $VERBOSE < $CORPUS_FILE > $VOCAB_FILE
echo "$ $BUILDDIR/cooccur -memory $MEMORY -vocab-file $VOCAB_FILE -verbose $VERBOSE -window-size $WINDOW_SIZE < $CORPUS_FILE > $COOCCURRENCE_FILE"
$BUILDDIR/cooccur -memory $MEMORY -vocab-file $VOCAB_FILE -verbose $VERBOSE -window-size $WINDOW_SIZE < $CORPUS_FILE > $COOCCURRENCE_FILE
echo "$ $BUILDDIR/shuffle -memory $MEMORY -verbose $VERBOSE < $COOCCURRENCE_FILE > $COOCCURRENCE_SHUF_FILE"
$BUILDDIR/shuffle -memory $MEMORY -verbose $VERBOSE < $COOCCURRENCE_FILE > $COOCCURRENCE_SHUF_FILE
echo "$ $BUILDDIR/glove -save-file $SAVE_FILE -threads $NUM_THREADS -input-file $COOCCURRENCE_SHUF_FILE -x-max $X_MAX -iter $MAX_ITER -vector-size $VECTOR_SIZE -binary $BINARY -vocab-file $VOCAB_FILE -verbose $VERBOSE"
$BUILDDIR/glove -save-file $SAVE_FILE -threads $NUM_THREADS -input-file $COOCCURRENCE_SHUF_FILE -x-max $X_MAX -iter $MAX_ITER -vector-size $VECTOR_SIZE -binary $BINARY -vocab-file $VOCAB_FILE -verbose $VERBOSE