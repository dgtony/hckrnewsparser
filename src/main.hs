import qualified Network.HTTP as HTTP
import Data.List.Split (splitOn)
import Data.List (isInfixOf, sortBy, reverse, foldl')
import Data.Char (toLower)
import qualified Data.Map as Map

import Options.Applicative
import Data.Semigroup ((<>))


data Args = Args 
    { fname :: String
    , addr :: String
    , numwords :: Int } deriving (Eq, Show)


arg :: Parser Args
arg = Args
    <$> strOption
        ( long "filter"
        <> short 'f'
        <> metavar "FILENAME"
        <> help "File containing filter words" )
    <*> strOption
        ( long "address"
        <> short 'a'
        <> metavar "ADDR"
        <> showDefault
        <> value "http://hckrnews.com"
        <> help "Address of web-page to analyze" )
    <*> option auto
        ( long "words"
        <> help "Number of top words to show"
        <> short 'w'
        <> metavar "INT"
        <> showDefault
        <> value 100 )


type WordFrequency = [(String, Int)]


getMainPage :: String -> IO String
getMainPage p = do
    resp <- HTTP.simpleHTTP (HTTP.getRequest p)
    HTTP.getResponseBody resp


getHTMLBody :: String -> String
getHTMLBody resp = unwords . dropWhile (/= "<body>") $ words resp


splitOnBlocks :: String -> [String]
splitOnBlocks = getLinks . getBlocks
    where getBlocks s = concatMap (splitOn "</a>") $ splitOn "<a " s
          getLinks = filter (isInfixOf "href=")


getHeadlines :: [String] -> [String]
getHeadlines = map (cleanHL . getHL)
    where getHL = takeWhile (/='<') . tail . dropWhile (/='>')
          cleanHL = filter (`notElem` "(){}[]<>,./:;%&\\!?")


getWords :: [String] -> [String]
getWords = map (map toLower) . concatMap words


histogram :: [String] -> Map.Map String Int
histogram = foldl' helper Map.empty
    where helper acc w = if Map.member w acc
                            then Map.update (\ n -> Just (n + 1)) w acc
                            else Map.insert w 1 acc


-- compare arguments are flipped for the descending order
sortHist :: Map.Map String Int -> WordFrequency
sortHist = sortBy (\x1 x2 -> compare (snd x2) (snd x1)) . Map.toList


prettyPrint :: WordFrequency -> Int -> IO ()
prettyPrint wfl num = do
    putStrLn $ "Most frequent words (top " ++ show num ++ "):"
    mapM_ (\(e, n) -> putStrLn $ e ++ ": " ++ show n) $ take num wfl


filterWords :: [String] -> WordFrequency -> WordFrequency
filterWords fw = filter (\(w,_) -> w `notElem` fw)


main = do
    let opts = info (arg <**> helper) ( fullDesc
            <> progDesc "Get most frequent words from Hacker News"
            <> header "Parse main page of HackerNews and show the most frequent words" )
    args <- execParser opts

    fd <- readFile (fname args)
    mp <- getMainPage (addr args)
    let fw = lines fd
        h = filterWords fw . sortHist . histogram . getWords . getHeadlines . splitOnBlocks . getHTMLBody $ mp
    prettyPrint h (numwords args)


