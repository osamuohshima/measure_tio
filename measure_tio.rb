#使い方
# ruby measure_tio_ews.rb @oto_out2.lst >ews_oto.txt
#各バンドの赤側ピーク平均位置を結ぶ線より下の吸収等価幅を測定　20230212
#各スペクトルのファイル名中には、YYYYMMDDかJD整数7桁が含まれていること

$band=[[4950,5160],[5160,5445],
      [5445,5843],[5843,6148],[6148,6472]]    #ew1-5
$clf=[4955,5167,5448,5846,6159,6470] #the cliffs n=6  
$d1=[1.0,1.5,1.5,1.5,3.5,4.5]   #distance from the red cliff = red limmit of the range
$d2=[10,10,19,35,22,20]       #width of the range to be measured    
require "numo/gnuplot"
require 'date'
def get_peak(i)  #ピーク範囲の平均位置座標を得る
  red=get_red_cliff($clf[i].to_i).to_i
  sub_sp=get_subsp([red-$d2[i]-$d1[i],red-$d1[i]])
  get_mean(sub_sp)
end
def get_diff(sp)  #スペクトルの波長微分
  n=sp[0].size
  dfsp=[[],[]]
  (1..n-3).each do |i|
    df=(sp[1][i+1].to_f+sp[1][i+2].to_f)-(sp[1][i].to_f+sp[1][i-1].to_f) 
    dfsp[1].push(df) 
    dfsp[0].push(sp[0][i].to_f)
  end
  return dfsp
end
def get_red_cliff(red_cliff)  #引数はBandHeadの固定波長
  dlamb=20          #red_cliffで指定した波長の±20Aの範囲でBandHeadを探す
  range=[red_cliff-dlamb,red_cliff+dlamb]
  sub_sp=get_subsp(range)
  diffsp=get_diff(sub_sp)
  index_red_cliff=diffsp[1].index(diffsp[1].min)
  return diffsp[0][index_red_cliff].to_f  
end      #戻り値は実際のBandHead波長

def get_subsp(range)  #rangeは[l0,l1] 
  sub_sp=[[],[]]
  (0..$n-1).each  do |i|
    lmd=$sp[0][i].to_f
    if lmd > range[0].to_f and lmd < range[1].to_f
      sub_sp[0] << $sp[0][i].to_f
      sub_sp[1] << $sp[1][i].to_f
    end
  end
  return sub_sp 
end

def get_mean(range)  #指定した波長範囲におけるスペクトルの平均の座標
  sum=0
  n=range.size
  (0..n-1).each do |i|
    flx=range[1][i].to_f 
    sum=sum+flx
  end
  mid_lamd=(range[0][0].to_f+range[0][-1].to_f)/2.0
  return mid_lamd,sum/n
end

def get_area(sp,line)  #直線lineと波長範囲におけるスペクトルspとで囲まれた面積（spは直線より下とする）
  sum=0
  n=sp[0].size
  (0..n-1).each do |i|
    df=(line[0]*sp[0][i]+line[1])-sp[1][i]
    sum=sum+df
  end
  sum=sum*(sp[0][n-1]-sp[0][0])/n  
  mid_flx=line[0]*sp[0][(n/2).to_i]+line[1]
  return sum /mid_flx   #等価幅単位
end
def get_line(a1,a2)
    #2点a1[x1,y1],a2[x2,y2]を通る直線の方程式
  x1=a1[0]
  y1=a1[1]
  x2=a2[0]
  y2=a2[1] 
  a=(y2-y1)/(x2-x1)
  b=y1-a*x1
  return a,b   #傾き、切片
end
def get_jd(filename)  #ファイル名中のyyyymmddを検出しJDを得る
  data=filename.chomp.split
  if date=data[0].to_s[/\d{8}/]
    /(\d{4})(\d{2})(\d{2})/=~date
    jd=Date.new($1.to_i,$2.to_i,$3.to_i).jd
  else
    jd=data[0].to_s[/\d{7}/].to_f  #ファイル名中にJDが与えられている場合
  end
end
def measure(data_file)  #1本のSpについてTiO吸収等価幅を測定
  jd=get_jd(data_file)
  f=open data_file
  d=f.readlines
  $n=d.size
  $sp=[[],[]] #array fo the spectrum
            # $sp[[l0,l1,l2,,,],[f0,f1,2,,,]]
  d.each do |l|     #扱いやすい配列に変換
    ls = l.strip.split
    $sp[0] << ls[0]    #lambda
    $sp[1] << ls[1]    #flux
  end
  result=[[],[[],[]],[]]    #ew,fl_mid,df
  peaks=[]
  (0..5).each do |i|
    peak_ib=get_peak(i)
    peaks << peak_ib
  end  
  (0..4).each do |i|
    line=get_line(peaks[i],peaks[i+1])
    sub_sp=get_subsp($band[i])
    ew=get_area(sub_sp,line)
    result[0].push(sprintf "%10.6f",ew)
    result[1][0] << peaks[i][0].to_f
    result[1][1] << peaks[i][1].to_f
    if i==4
      result[1][0] << peaks[i+1][0].to_f
      result[1][1] << peaks[i+1][1].to_f
    end 
  end
  Numo.gnuplot do       #gnuplotを使ってスペクトル上に測定範囲を図示
    set title: File.basename(data_file)
    set terminal: "pngcairo"  
    set output: "./png/"+File.basename(data_file,".*")+".png"
    set xrange: 4500..6750 
    set key: "top left"
    plot [$sp[0],$sp[1], w:"lines"],[result[1][0],result[1][1], w:"linespoints", lw:2]
  end  
  printf "%-26s %7.0f \t",File.basename(data_file),jd
  (0..4).each do |i|
    printf "%7.3f   ",result[0][i]
  end
  print "\n"
end

#メインルーチン
puts "#file name                JD      \t ew1       ew2       ew3       ew4       ew5"
args=+ARGV[0].to_s
if args.start_with? '@' #ファイルリスト名に＠をつけた場合
  args.slice!(0,1)
  open args do |f|
    lst=f.readlines
    lsize=lst.size
    (0..lsize-1).each do |i|
      measure(lst[i].strip)
    end
  end    
else
  measure(args)  #単一ファイルのみ
end 

