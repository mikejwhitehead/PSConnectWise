class PSCString
{
    [string] static ToLowerCaseFirst ([string] $string)
    {
        if ([String]::IsNullOrEmpty($string))
        {
            return $string;
        }

        $result = [String]::Empty;
        $result += $string.Substring(0,1).ToLower()
        $result += $string

        return $result;
    }
}